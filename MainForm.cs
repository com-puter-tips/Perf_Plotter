using System;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Windows.Forms;

namespace perfloggengui
{
	public partial class MainForm : Form
	{
		public MainForm()
		{
			InitializeComponent();
		}
		
		void Button2Click(object sender, EventArgs e)
		{
			if (saveFileDialog1.ShowDialog() == DialogResult.OK)
				textBox2.Text = saveFileDialog1.FileName;
		}
		
		void Button1Click(object sender, EventArgs e)
		{
			textBox3.AppendText("Processing started at " + DateTime.Now + "..." + Environment.NewLine + Environment.NewLine + "please wait..." + Environment.NewLine +
			                    Environment.NewLine);
			LogStatistics(textBox1.Text, textBox2.Text);
			textBox3.AppendText("Processing finished at " + DateTime.Now + "..." + Environment.NewLine + Environment.NewLine +
			                    "Log generated successfully to location " + textBox2.Text);
		}
		
		public static string getCurrentCpuUsage()
		{
			var cpuCounter = new PerformanceCounter();
			cpuCounter.CategoryName = "Processor";
			cpuCounter.CounterName = "% Processor Time";
			cpuCounter.InstanceName = "_Total";
			return cpuCounter.NextValue() + "%";
		}

		public static string getAvailableRAM()
		{
			var ramCounter = new PerformanceCounter("Memory", "Available MBytes");
			return ramCounter.NextValue() + "MB";
		}
		
		public static void LogStatistics(string command, string path)
		{
			Process myProcess = null;

			try
			{
				var searcher1 = new ManagementObjectSearcher("root\\CIMV2", "SELECT * FROM Win32_PerfFormattedData_Counters_ProcessorInformation " +
				                                             "WHERE NOT Name='_Total' AND NOT Name='0,_Total'");

				var searcher2 = new ManagementObjectSearcher("root\\CIMV2", "SELECT * FROM Win32_OperatingSystem");

				var searcher3 = new ManagementObjectSearcher("select * from Win32_PerfFormattedData_PerfOS_Processor WHERE Name='_Total'");

				var searcher4 = new ManagementObjectSearcher("select CurrentClockSpeed from Win32_Processor");

				File.WriteAllText(path, "Timestamp,Total_Memory_Used_GB,Total_Memory_Used,Working_Set_GB,Peak_Working_Set_GB,CPU_Clock_MHz,CPU_Usage," +
				                  "Cores_Usage\n");
				
				var procInfo = new ProcessStartInfo();
				
				procInfo.FileName = command;

				myProcess = Process.Start(procInfo);

				do
				{
					if (!myProcess.HasExited)
					{
						File.AppendAllText(path, DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss.ffffff") + ",");

						for (var i = searcher2.Get().GetEnumerator(); i.MoveNext();)
						{
							var queryObj = (ManagementObject)i.Current;
							double free = Double.Parse(queryObj["FreePhysicalMemory"].ToString());
							double total = Double.Parse(queryObj["TotalVisibleMemorySize"].ToString());
							File.AppendAllText(path, (total - free) / (1024 * 1024) + "," + ((total - free) / total) * 100 + "," +
							                   (double)myProcess.WorkingSet64 / (1024 * 1024 * 1024) + "," +
							                   (double)myProcess.PeakWorkingSet64 / (1024 * 1024 * 1024) + ",");
						}

						for (var i = searcher4.Get().GetEnumerator(); i.MoveNext();)
						{
							var item = (ManagementObject)i.Current;
							var curSpeed = (uint)item["CurrentClockSpeed"];
							File.AppendAllText(path, curSpeed + ";");
						}
						File.AppendAllText(path, ",");

						foreach (ManagementBaseObject obj in searcher3.Get())
						{
							var usage = obj["PercentProcessorTime"];
							File.AppendAllText(path, usage + ",");
						}

						for (var i = searcher1.Get().GetEnumerator(); i.MoveNext();)
						{
							var queryObj = (ManagementObject)i.Current;
							File.AppendAllText(path, queryObj["PercentProcessorTime"] + ";");
						}

						File.AppendAllText(path, "\n");
						myProcess.Refresh();
					}
				}
				while (!myProcess.WaitForExit(500));
			}
			
			catch(Exception expt)
			{
				MessageBox.Show(expt.ToString());
			}
			
			finally
			{
				if (myProcess != null)
					myProcess.Close();
			}
		}
	}
}