#!/bin/bash

NSXUSER='youruserhere'
#NSXPASS='yourpasswordhere'
NSXMAN='yournsxmanagerhere'

read -s -p "Password: " NSXPASS

#txt files cleanup

rm -rf *.txt


#Group Configuration

RULES="rules.list"
RULESEQ=0

for RULELINE in `cat $RULES`

do

RULESEQ=$(( $RULESEQ + 1))

SECTIONVAR=`echo $RULELINE | cut -f1 -d","`
ACTIONVAR=`echo $RULELINE | cut -f5 -d","`
SOURCEVAR=`echo $RULELINE | cut -f3 -d","`
DESTINATIONVAR=`echo $RULELINE | cut -f4 -d","`
SERVICEVAR="ANY"
RULEVAR=`echo $RULELINE | cut -f2 -d","`

#Group Creation

cat > Group$RULEVAR.txt << EOL
{
    "expression": [
      {
        "member_type" : "VirtualMachine",
        "key" : "Name",
        "operator" : "EQUALS",
        "value" : "$RULEVAR",
        "resource_type" : "Condition"
      }
    ],
    "description": "Group for Server agency $RULEVAR",
    "display_name": "Server-$RULEVAR"
}
EOL

echo "Creating Group for Server Agency $RULEVAR with the IP Address $DESTINATIONVAR"

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1/infra/domains/default/groups/Server-$RULEVAR -X PATCH --data @Group$RULEVAR.txt -H "Content-Type: application/json"

sleep 1


#Create the DFW Rule

cat > DFW-$SECTIONVAR$RULEVAR.txt << EOL
{
    "rules": [
      {
        "description": "DFW Rule for Server Agency $RULEVAR",
        "display_name": "$RULEVAR",
        "source_groups": [
          "$SOURCEVAR"
        ],
        "destination_groups": [
          "/infra/domains/default/groups/Server-$RULEVAR"
        ],
        "services": [
          "$SERVICEVAR"
        ],
        "action": "ALLOW",
        "scope": [
          "/infra/domains/default/groups/Server-$RULEVAR"
        ]
      }

    ]
}

EOL

echo "Creating DFW Rule for Server Agency $RULEVAR with the Source IP Address $SOURCEVAR and Destination IP Address $DESTINATIONVAR"

curl -k --user $NSXUSER:$NSXPASS https://$NSXMAN/policy/api/v1/infra/domains/default/security-policies/$SECTIONVAR -X PATCH --data @DFW-$SECTIONVAR$RULEVAR.txt -H "Content-Type: application/json"

sleep 1


done


#Clean up

read -p "Do you want to delete the .txt files created for migration? (Y/N)"  -r CHOICE
echo
if [[ $CHOICE =~ ^[Yy]$ ]];

then

echo "Deleting .txt files"
rm -rf *.txt

else
echo "Saving the .txt files"

fi

echo "Task completed! $RULESEQ rule(s) have been configured in NSX $NSXMAN."
