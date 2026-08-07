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
                Console.WriteLine("Connect() returned directly.");
            } catch (Win32Exception wex) when (wex.NativeErrorCode == 0 || wex.Message.Contains("completed successfully")) {
                Console.WriteLine("CAUGHT Win32Exception 0: " + wex.Message);
            }
            
            Console.WriteLine("Updating axes (LeftThumbX = 16000, RightThumbY = 30000)...");
            target.SetAxisValue(Nefarius.ViGEm.Client.Targets.Xbox360.Xbox360Axis.LeftThumbX, 16000);
            target.SetAxisValue(Nefarius.ViGEm.Client.Targets.Xbox360.Xbox360Axis.RightThumbY, 30000);
            target.SubmitReport();
            Console.WriteLine("SUCCESSFULLY SUBMITTED REPORT TO VIRTUAL XBOX 360 CONTROLLER!");
            
            System.Threading.Thread.Sleep(3000);
            target.Disconnect();
            Console.WriteLine("Disconnected.");
        } catch (Exception ex) {
            Console.WriteLine("FATAL EXCEPTION: " + ex.ToString());
        }
    }
}
