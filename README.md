# SQLBkpMod
AddOn to Ola Hallengren's Maintenance Solution
https://github.com/olahallengren

Hallengreen's solution is great and we've been using it for several years. But we hardly have dedicated SQL Server 
but central SQL clusters with many different databases. We were looking for a backup option that offered a degree of flexibility 
in terms of comfortability. That's why we've expanded the solution for our purposes.
We have created a table that we update daily. The Table contains the database names as well as other (for us) important parameters.
A second Table with defaultparameters.
Our guidelines are: a full backup once a week, an incremental daily and TLog backups depending on the database mode and usage.
For the full backup, there is usually a time frame or a time from which the full may be started.


Since we did not want to modify the original scripts, we built the solution on top and therefore did not pay attention to duplication or optimization possibilities.
Also, this is a tailored solution for us, which means that we intercept errors only conditionally

(I hope that my translationprogram did everything right)
