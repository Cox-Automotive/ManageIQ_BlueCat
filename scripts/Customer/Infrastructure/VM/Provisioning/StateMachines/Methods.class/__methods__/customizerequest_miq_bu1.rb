###################################
#
# EVM Automate Method: customizerequest_miq_bu1
#
# Notes: This method is used to Customize the Provisioning Request
#
# 1. Customization Specification Mapping
#
###################################
# Method for logging
###################################
def log(level, message)
  @method = 'customizerequest_miq_bu1'
  @debug = true
  $evm.log(level, "#{@method} - #{message}") if @debug
end

#################################
# Method: set_customspec
#################################
def set_customspec(prov, spec)
  prov.set_customization_spec(spec)
  log(:info, "Provisioning object updated - <:sysprep_custom_spec> = <#{spec}>")
  prov.set_option(:sysprep_spec_override, [true, 1])
  log(:info, "Provisioning object <:sysprep_spec_override> updated with <#{prov.get_option(:sysprep_spec_override)}>")
end

###################################
# Method: boolean
###################################
def boolean(string)
  return true if string == true || string =~ (/(true|t|yes|y|1)$/i)
  return false if string == false || string.nil? || string =~ (/(false|f|no|n|0)$/i)

  # Return false if string does not match any of the above
  log(:info, "Invalid boolean string:<#{string}> detected. Returning false")
  return false
end


begin
  log(:info, "===== EVM Automate Method: Started")

  # Get provisioning object
  prov = $evm.root["miq_provision"]
  tags = prov.get_tags
  log(:info, " Inspecting tags: #{tags.inspect}")


  IPAM_Source = 'IP_MGR_Lab_v4_0'
  prov.add_tag(:ipam_source, IPAM_Source)

  #########  JD: 20140311
  #  To make the AcquireIPAddress code more universal, moved IPAM DB naming code to the CustomizeRequest.
  #  Create the IPAM Database name variable then add as a tag (ipam_path) used for provisioning and retirement.
  #  We also use this section to set any Env/Location settings
  #########
  env = tags[:atg_env]
  case env
    when "dev"
      default_folder = "ManageIQ/lab/dev"
      IPAM_name = "IP_MGR_10_111_111_0"
      IPAM_name2 = "IP_MGR_10_111_222_0"
    when "qa"
      default_folder = "ManageIQ/lab/qa"
      IPAM_name = "IP_MGR_10_222_11_0"
      IPAM_name2 = "IP_MGR_10_222_22_0"
  end

  prov.add_tag(:ipam_path, IPAM_name)
  log(:info, "Tag ipam_path: #{IPAM_name}")

  prov.add_tag(:ipam_path2, IPAM_name2)
  log(:info, "Tag ipam_path2: #{IPAM_name2}")

  prov.set_folder(default_folder)
  log(:info, "Provisioning object <:placement_folder_name> updated with <#{default_folder}>")


  #################################
  # Custom Specification Mapping
  #################################
  spec = 'CFA_SPEC_BU1'
  log(:info, "Logically changed customization specification mapping to #{spec}")
  set_customspec(prov, spec)


  #########  JD: 20140311
  #  For this workflow, we'll control the sizing
  #########
  prov.set_option(:number_of_sockets, '2')
  prov.set_option(:cores_per_socket, '1')
  prov.set_option(:vm_memory, '2048')
  prov.set_option(:memory_limit, '-1')
  prov.set_option(:retirement, 0)

  prov.options.each { |k, v| log(:info, "Provisioning Option Key:<#{k.inspect}> Value:<#{v.inspect}>") }


  ###################################
  # Set the VM Description and VM Annotations  as follows:
  # The example would allow user input in provisioning dialog "vm_description"
  # to be added to the VM notes
  ###################################
  # Stamp VM with custom description
  unless prov.get_option(:vm_description).nil?
    vmdescription = prov.get_option(:vm_description)
    prov.set_option(:vm_description, vmdescription)
    log(:info, "Provisioning object <:vmdescription> updated with <#{vmdescription}>")
  end

  # Setup VM Annotations
  vm_notes = prov.get_option(:vm_notes) || ""
  vm_notes += "Owner: #{prov.get_option(:owner_first_name)} #{prov.get_option(:owner_last_name)}"
  vm_notes += "\nEmail: #{prov.get_option(:owner_email)}"
  vm_notes += "\nSource Template: #{prov.vm_template.name}"
  vm_notes += "\nCustom Description: #{vmdescription}" unless vmdescription.nil?
  vm_notes += "\nWorkflow: MIQ_BU1"
  prov.set_vm_notes(vm_notes)
  log(:info, "Provisioning object <:vm_notes> updated with <#{vm_notes}>")

  #
  # Exit method
  #
  log(:info, "===== EVM Automate Method: Ended")
  exit MIQ_OK

    #
    # Set Ruby rescue behavior
    #
rescue => err
  log(:error, " [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
###################################
# End of Automate Method: customizerequest_miq_bu1
###################################
