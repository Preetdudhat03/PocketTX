using System;
using Nefarius.ViGEm.Client;

class Program {
    static void Main() {
        try {
            Console.WriteLine("Initializing ViGEmClient...");
            var client = new ViGEmClient();
            Console.WriteLine("Creating Xbox 360 Controller target...");
            var target = client.CreateXbox360Controller();
            Console.WriteLine("Connecting target to Windows ViGEmBus...");
            target.Connect();
            Console.WriteLine("SUCCESS: Xbox 360 Controller connected!");
            System.Threading.Thread.Sleep(5000);
            target.Disconnect();
            Console.WriteLine("Disconnected.");
        } catch (Exception ex) {
            Console.WriteLine("EXCEPTION: " + ex.GetType().FullName);
            Console.WriteLine("MESSAGE: " + ex.Message);
            Console.WriteLine("STACKTRACE:\n" + ex.StackTrace);
        }
    }
}
