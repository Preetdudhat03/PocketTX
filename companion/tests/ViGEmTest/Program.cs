using System;
using System.ComponentModel;
using Nefarius.ViGEm.Client;

class Program {
    static void Main() {
        try {
            var client = new ViGEmClient();
            var target = client.CreateXbox360Controller();
            try {
                target.Connect();
            } catch (Win32Exception wex) when (wex.NativeErrorCode == 0 || wex.Message.Contains("completed successfully")) {
                Console.WriteLine("Win32Exception ignored because NativeErrorCode == 0 (" + wex.Message + ")");
            }
            Console.WriteLine("IsConnected: " + target.IsConnected);
            if (target.IsConnected) {
                Console.WriteLine("SUCCESS! Xbox 360 Controller connected!");
                System.Threading.Thread.Sleep(5000);
                target.Disconnect();
            }
        } catch (Exception ex) {
            Console.WriteLine("FATAL EXCEPTION: " + ex.ToString());
        }
    }
}
