// Uses the Steam API DLL already installed with Project Zomboid. No SDK binaries are distributed.
// Native signatures and callback layouts: Valve's steam_api.h, steam_api_flat.h and isteamugc.h.
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace PZModTools
{
    public sealed class SteamWorkshopClient : IDisposable
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr LoadLibraryEx(string file, IntPtr reserved, uint flags);
        [DllImport("kernel32.dll", CharSet = CharSet.Ansi, ExactSpelling = true)]
        private static extern IntPtr GetProcAddress(IntPtr module, string name);
        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool FreeLibrary(IntPtr module);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)] [return: MarshalAs(UnmanagedType.I1)]
        private delegate bool Init();
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int InitFlat(IntPtr error);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate void VoidCall();
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int GetPipe();
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate IntPtr GetInterface();
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate uint AppId(IntPtr self);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate void PipeCall(int pipe);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)] [return: MarshalAs(UnmanagedType.I1)]
        private delegate bool NextCallback(int pipe, out CallbackMessage message);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)] [return: MarshalAs(UnmanagedType.I1)]
        private delegate bool CallResult(int pipe, ulong call, IntPtr data, int size, int expected,
            [MarshalAs(UnmanagedType.I1)] out bool failed);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate ulong Subscribe(IntPtr self, ulong id);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate uint ItemState(IntPtr self, ulong id);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)] [return: MarshalAs(UnmanagedType.I1)]
        private delegate bool Download(IntPtr self, ulong id, [MarshalAs(UnmanagedType.I1)] bool highPriority);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)] [return: MarshalAs(UnmanagedType.I1)]
        private delegate bool InstallInfo(IntPtr self, ulong id, out ulong size, [Out] byte[] folder,
            uint capacity, out uint timestamp);

        // Windows Steam callbacks use 8-byte packing, including the 64-bit PublishedFileId.
        [StructLayout(LayoutKind.Sequential, Pack = 8)]
        public struct CallbackMessage { public int User; public int Callback; public IntPtr Data; public int Size; }
        [StructLayout(LayoutKind.Sequential, Pack = 8)]
        public struct ApiCallCompleted { public ulong Call; public int Callback; public uint Size; }
        [StructLayout(LayoutKind.Sequential, Pack = 8)]
        public struct SubscriptionResult { public int Result; public ulong Id; }
        [StructLayout(LayoutKind.Sequential, Pack = 8)]
        public struct DownloadResult { public uint App; public ulong Id; public int Result; }

        private IntPtr module, ugc;
        private int pipe;
        private bool initialized;
        private VoidCall shutdown;
        private PipeCall runFrame, freeCallback;
        private NextCallback nextCallback;
        private CallResult callResult;
        private Subscribe subscribe;
        private ItemState itemState;
        private Download download;
        private InstallInfo installInfo;
        private readonly Dictionary<ulong, ulong> subscriptions = new Dictionary<ulong, ulong>();
        private readonly Dictionary<ulong, int> downloadResults = new Dictionary<ulong, int>();

        private T Function<T>(string name) where T : class
        {
            IntPtr address = GetProcAddress(module, name);
            if (address == IntPtr.Zero)
                throw new InvalidOperationException("The game's Steam API lacks " + name + ". Verify/update Project Zomboid in Steam.");
            return Marshal.GetDelegateForFunctionPointer(address, typeof(T)) as T;
        }

        private IntPtr Interface(string prefix)
        {
            // Choose an interface getter exported by the installed DLL, rather than hard-coding an SDK release.
            for (int version = 40; version >= 1; version--)
            {
                IntPtr address = GetProcAddress(module, prefix + version.ToString("000"));
                if (address == IntPtr.Zero) continue;
                IntPtr result = ((GetInterface)Marshal.GetDelegateForFunctionPointer(address, typeof(GetInterface)))();
                if (result != IntPtr.Zero) return result;
            }
            throw new InvalidOperationException("No supported " + prefix + " interface. Update Steam and Project Zomboid.");
        }

        public SteamWorkshopClient(string dllPath)
        {
            if (IntPtr.Size != 8) throw new InvalidOperationException("Use 64-bit PowerShell for client mode.");
            // Resolve dependencies only from the DLL directory and Windows' safe default locations.
            module = LoadLibraryEx(dllPath, IntPtr.Zero, 0x00000100 | 0x00001000);
            if (module == IntPtr.Zero)
                throw new InvalidOperationException("Cannot load the game's Steam API DLL (Windows error " + Marshal.GetLastWin32Error() + ").");
            try
            {
                shutdown = Function<VoidCall>("SteamAPI_Shutdown");
                runFrame = Function<PipeCall>("SteamAPI_ManualDispatch_RunFrame");
                freeCallback = Function<PipeCall>("SteamAPI_ManualDispatch_FreeLastCallback");
                nextCallback = Function<NextCallback>("SteamAPI_ManualDispatch_GetNextCallback");
                callResult = Function<CallResult>("SteamAPI_ManualDispatch_GetAPICallResult");
                subscribe = Function<Subscribe>("SteamAPI_ISteamUGC_SubscribeItem");
                itemState = Function<ItemState>("SteamAPI_ISteamUGC_GetItemState");
                download = Function<Download>("SteamAPI_ISteamUGC_DownloadItem");
                installInfo = Function<InstallInfo>("SteamAPI_ISteamUGC_GetItemInstallInfo");
                IntPtr flatInit = GetProcAddress(module, "SteamAPI_InitFlat");
                initialized = flatInit != IntPtr.Zero
                    ? ((InitFlat)Marshal.GetDelegateForFunctionPointer(flatInit, typeof(InitFlat)))(IntPtr.Zero) == 0
                    : Function<Init>("SteamAPI_Init")();
                if (!initialized)
                    throw new InvalidOperationException("Cannot connect to Steam. Run Steam, sign into an account owning Project Zomboid, and install the game before retrying.");
                IntPtr utils = Interface("SteamAPI_SteamUtils_v");
                if (Function<AppId>("SteamAPI_ISteamUtils_GetAppID")(utils) != 108600)
                    throw new InvalidOperationException("Steam initialized for the wrong game; expected Project Zomboid (108600).");
                ugc = Interface("SteamAPI_SteamUGC_v");
                pipe = Function<GetPipe>("SteamAPI_GetHSteamPipe")();
                Function<VoidCall>("SteamAPI_ManualDispatch_Init")();
            }
            catch { Dispose(); throw; }
        }

        public void SubscribeItem(ulong id)
        {
            if ((GetItemState(id) & 1) != 0) return;
            ulong call = subscribe(ugc, id);
            if (call == 0) throw new InvalidOperationException("Steam rejected subscription for Workshop " + id + ".");
            subscriptions[call] = id;
        }

        public bool SubscriptionPending(ulong id) { return subscriptions.ContainsValue(id); }
        public uint GetItemState(ulong id) { return itemState(ugc, id); }

        public bool DownloadItem(ulong id)
        {
            downloadResults.Remove(id);
            return download(ugc, id, false);
        }

        // Zero means no result yet; one is Valve's k_EResultOK.
        public int GetDownloadResult(ulong id)
        {
            int result;
            return downloadResults.TryGetValue(id, out result) ? result : 0;
        }

        public string GetInstallFolder(ulong id)
        {
            ulong size;
            uint timestamp;
            byte[] folder = new byte[32768];
            if (!installInfo(ugc, id, out size, folder, (uint)folder.Length, out timestamp)) return null;
            int end = Array.IndexOf(folder, (byte)0);
            return Encoding.UTF8.GetString(folder, 0, end < 0 ? folder.Length : end);
        }

        public void Pump()
        {
            runFrame(pipe);
            CallbackMessage message;
            while (nextCallback(pipe, out message))
            {
                try
                {
                    if (message.Callback == 703 && message.Size >= Marshal.SizeOf(typeof(ApiCallCompleted)))
                    {
                        ApiCallCompleted completed = (ApiCallCompleted)Marshal.PtrToStructure(message.Data, typeof(ApiCallCompleted));
                        ulong id;
                        if (!subscriptions.TryGetValue(completed.Call, out id)) continue;
                        if (completed.Callback != 1313 || completed.Size != Marshal.SizeOf(typeof(SubscriptionResult)))
                            throw new InvalidOperationException("Unexpected Steam subscription response for " + id + ".");
                        IntPtr data = Marshal.AllocHGlobal((int)completed.Size);
                        try
                        {
                            bool failed;
                            if (!callResult(pipe, completed.Call, data, (int)completed.Size, 1313, out failed) || failed)
                                throw new InvalidOperationException("Steam subscription failed for Workshop " + id + ".");
                            SubscriptionResult result = (SubscriptionResult)Marshal.PtrToStructure(data, typeof(SubscriptionResult));
                            if (result.Id != id || result.Result != 1)
                                throw new InvalidOperationException("Steam subscription failed for Workshop " + id + " (EResult=" + result.Result + ").");
                            subscriptions.Remove(completed.Call);
                        }
                        finally { Marshal.FreeHGlobal(data); }
                    }
                    else if (message.Callback == 3406 && message.Size >= Marshal.SizeOf(typeof(DownloadResult)))
                    {
                        DownloadResult result = (DownloadResult)Marshal.PtrToStructure(message.Data, typeof(DownloadResult));
                        if (result.App == 108600) downloadResults[result.Id] = result.Result;
                    }
                }
                finally { freeCallback(pipe); }
            }
        }

        public void Dispose()
        {
            if (initialized) { initialized = false; shutdown(); }
            if (module != IntPtr.Zero) { FreeLibrary(module); module = IntPtr.Zero; }
        }
    }
}
