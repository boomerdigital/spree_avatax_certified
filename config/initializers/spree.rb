Spree.user_class = "Spree::LegacyUser"
Spree::PermittedAttributes.user_attributes.concat([:avalara_entity_use_code_id, :exemption_number])
