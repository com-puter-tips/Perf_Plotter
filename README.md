# Perf_Plotter
Visualizing system performance for your appliation.

This is a tool that will help you benchmark the performance of your application. It has two parts: A logging mechanism buint in C# and plotting utility made in R. A windows forms in C# is created so you can execute your application from it and log the data in a csv file. This csv file you have to upload in shiny web application in R so it can read it and plot it. For more information refer my paper:
https://www.irjet.net/archives/V3/i3/IRJET-V3I3193.pdf

Perf_Plotter.zip file contains two folders and one file. It is as following:
1. perfloggengui directory
2. Uploads directory
3. app.R file

(1) perfloggengui
It contains C# solution for generating logs from your application.

(2) Uploads
It has sample log files to get you started with.

(3) app.R
It is the shiny app that you are supposed to run in R.
