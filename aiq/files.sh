
#get the files:

./sftp_to_s3.py --host analytics-iq.files.com --remote-path "Customers/Growth Health/{file-name}"  --secret-name AnalyticsIQ/sftp --s3-bucket gh-prod-cdc-aiq --s3-prefix gv/data-proc/aiq/{run-date}/in

#B2B
GH_B2B_105_Extract.txt.gz

# NPI
GH_HCP_matched_105_Extract.txt.gz

#AIQ
GrowthHealth_Extract_V105_HH.txt.gz

AIQ part 2
GrowthHealth_Extract_V105_HH_Skinny.txt


#not using these
GH_HCP_Non_matched_105_Extract.txt.gz
GrowthHealth_Extract_V105_Zip4.txt.gz
GrowthHealth_Extract_V105_Zip4_Skinny.txt.gz


 
1.) B2B connection+ file
2.) HCP data (already delivered for v105)
3.) Main Consumer quarterly file (same old layout)
4.) Skinny Consumer quarterly file (the new SDOH fields)
 
Connection+ 
The first file connects ~75MM business contacts to their consumer ID’s.  
GH_B2B_105_Extract.txt.gz : 75,348,719
 
 
HCP data -
 
GH_HCP_matched_105_Extract.txt.gz : 6,932,349
GH_HCP_Non_matched_105_Extract.txt.gz : 1,903,964
 
 
Consumer install file -
 
Main files:
Layout stay the same.  These will be update to v104 and be delivered.
HH/IND
GrowthHealth_Extract_V105_HH.txt.gz : 265,102,003

Zip4
GrowthHealth_Extract_V105_Zip4.txt.gz : 43,832,522
 
Skinny file:   
These files have the newly added SDOH data fields.
HH/IND
GrowthHealth_Extract_V105_HH_Skinny.txt.gz : 265,102,003

Zip4
GrowthHealth_Extract_V105_Zip4_skinny.txt.gz : 32,193,804

