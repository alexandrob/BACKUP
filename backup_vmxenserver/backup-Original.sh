#!/bin/bash

# Settings

backup_dir="/var/run/sr-mount/<UUID>/"
backup_ext=".xva"
date=$(date +%Y-%m-%d_%H-%M-%S)

# VMs to backup
vm_backup_list=()

vm_backup_list[1]="<UUID>"






vm_backup_list_count=${#vm_backup_list[@]}

# Get VM list

vm_list_string=`xe vm-list is-control-domain=false`
IFS="
"
vm_list_array=($vm_list_string)
vm_list_count=${#vm_list_array[@]}

# Create arrays to use

vm_uuid_array=()
vm_label_array=()
vm_log=()


# Start Log

vm_log[${#vm_log[@]}]="Starting VM Backup: $date"
vm_log[${#vm_log[@]}]="-----------------------------"


# Get VMs to export

vm_log[${#vm_log[@]}]="Parsing VM list"

key=0
index=0

for line in ${vm_list_array[@]}; do

        if [ ${line:0:4} = "uuid" ]; then

                uuid=`expr "$line" : '.*: \(.*\)$'`
                label=`expr "${vm_list_array[key+1]}" : '.*: \(.*\)$'`

                vm_uuid_array[index]=$uuid
                vm_label_array[index]=$label

                vm_log[${#vm_log[@]}]="Added VM #$index: $uuid, $label"

                let "index = $index+1"

        fi


        let "key = $key+1"

done

vm_log[${#vm_log[@]}]="Done parsing VM list"


# Backup VMs

vm_log[${#vm_log[@]}]="Backup VMs"

key=0

for uuid in ${vm_uuid_array[@]}; do

        # Set VM backup state

        backup_vm=false

        # If the backup list is empty

        if [ $vm_backup_list_count = 0 ]; then

                # Backup all VMs

                backup_vm=true

        # Else check to see if the VM is to be backed up

        else

                for backup_uuid in ${vm_backup_list[@]}; do

                        if [ $uuid = $backup_uuid ]; then

                                backup_vm=true
                                break

                        fi

                done


        fi

        # If the VM is being backed up

        if [ $backup_vm = true ]; then

                # Log

                vm_log[${#vm_log[@]}]="VM: $uuid"

                # Label

                label=${vm_label_array[key]}

                # Create snapshot

                snapshot=`xe vm-snapshot vm=$uuid new-name-label=backup_$date`
                vm_log[${#vm_log[@]}]="Snapshot: $snapshot"

                # Set as VM not template

                snapshot_template=`xe template-param-set is-a-template=false uuid=$snapshot`
                vm_log[${#vm_log[@]}]="Set as VM"

                # Export

                snapshot_export=`xe vm-export vm=$snapshot filename="$backup_dir$label-$date$backup_ext"`

                vm_log[${#vm_log[@]}]="Export: $snapshot_export"

                # Delete snapshot

                snapshot_delete=`xe vm-uninstall uuid=$snapshot force=true`
                vm_log[${#vm_log[@]}]="Delete Snapshot: $snapshot_delete"

        # Else the VM isnt being backed up

        else

                # Log


                vm_log[${#vm_log[@]}]="VM: $uuid"
                vm_log[${#vm_log[@]}]="Ignoring Backup"

        fi

        # Increment Key

        let "key = $key+1"

done

vm_log[${#vm_log[@]}]="Export Complete"
vm_log[${#vm_log[@]}]="

"

# Logging

#echo ${vm_uuid_array[@]}
#echo ${vm_label_array[@]}

for log in ${vm_log[@]}; do
        echo $log
done
