#!/bin/bash
# simple script to automate some info gathering for a domain.
# output will go into ./quicklook/<TARGET>
# --nh
# @hakkavelli

TARGET=$1
REPORT=$1_report.txt

# functions
banner () {
	echo "  ______     __  __     __     ______     __  __     __         ______     ______     __  __    " 
	echo " /\  __ \   /\ \/\ \   /\ \   /\  ___\   /\ \/ /    /\ \       /\  __ \   /\  __ \   /\ \/ /    "
        echo " \ \ \/\_\  \ \ \_\ \  \ \ \  \ \ \____  \ \  _'-.  \ \ \____  \ \ \/\ \  \ \ \/\ \  \ \  _'-.  "
	echo "  \ \___\_\  \ \_____\  \ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\ "
	echo "   \/___/_/   \/_____/   \/_/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_____/   \/_/\/_/ "
	echo "                                                                        scripted by: hakkavelli "
}

report_it () {
	banner > quicklook/$TARGET/$REPORT
	echo "\nREPORT FOR: $TARGET" >> quicklook/$TARGET/$REPORT
	echo "\nTarget IP(s):\n" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/ip.out)\n" >> quicklook/$TARGET/$REPORT
	echo "Target whois info:\n" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/whois.out| grep -m1 "Admin Name" | sed 's/   //g')" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/whois.out| grep -m1 "Admin Email" | sed 's/   //g')" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/whois.out| grep -m1 "Creation Date" | sed 's/   //g')" >> quicklook/$TARGET/$REPORT	
	echo "$(cat quicklook/$TARGET/whois.out| grep -m1 "Expiry" | sed 's/   //g')" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/whois.out| grep -m1 "Updated Date" | sed 's/   //g')" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/whois.out| grep -m3 "Name Server" | sed 's/   //g')" >> quicklook/$TARGET/$REPORT
	echo "\nTarget Systems Open Ports:\n" >> quicklook/$TARGET/$REPORT
	for i in $(cat quicklook/$TARGET/ip.out)
	do cat quicklook/$TARGET/nmap_$i-filtered.out >> quicklook/$TARGET/$REPORT
	done
	echo "\nTarget Zone Transfer:" >> quicklook/$TARGET/$REPORT
	echo "$(cat quicklook/$TARGET/zone.out)" >> quicklook/$TARGET/$REPORT
}

dig_scan () {
	mkdir -p quicklook/$TARGET/
	touch quicklook/$TARGET/$REPORT
	echo "** Digging target...\n"
	dig A $TARGET +short | tee quicklook/$TARGET/ip.out
	echo "\nPulling whois info..."
	whois $TARGET > quicklook/$TARGET/whois.out
	echo "\n** Done resolving target. Initiating NMAP Scan, please be patient...\n"
	nmap_it
	clean_it
	report_it
}

nmap_it () {
	for i in $(cat quicklook/$TARGET/ip.out) 
	do nmap -vv -sV -p- $i -oG quicklook/$TARGET/nmap_$i.out
	done
}

clean_it () {
	for i in $(cat quicklook/$TARGET/ip.out)
	do egrep -v "^#|Status: Up" quicklook/$TARGET/nmap_$i.out | cut -d' ' -f2 -f4- | \
	awk '{print $1; $1=""; for(i=2; i<=NF; i++) { a=a" "$i; }; split(a,s,","); for(e in s) { split(s[e],v,"/"); printf "%-8s %s/%-7s %s\n", v[2], v[3], v[1], v[5]}; a=""; print "\n" }' > quicklook/$TARGET/nmap_$i-filtered.out
	done
}

if [[ $# -lt 1 || $# -gt 1 ]]
then
	banner
	echo "\nYou must enter a hostname or IP to run $0!\n"
	echo "example: ./quicklook.sh hackers.org\n"
exit 1
else
	banner
	echo "\n** Prepping output directories...\n"
	if [ -d quicklook/$TARGET ]
	then
		echo "Backing up older directory quicklook/$TARGET to $TARGET.old\n"
		echo "Anything older is expunged.\n"
		rm -rf quicklook/$TARGET.old
		mv quicklook/$TARGET quicklook/$TARGET.old
		dig_scan
	else
		dig_scan
	fi
fi

echo "\n** Scan complete. Generating report..."
cat quicklook/$TARGET/$REPORT
echo "** Complete! Report is available in quicklook/$TARGET/$REPORT\n"