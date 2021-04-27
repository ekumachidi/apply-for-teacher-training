# PaaS
paas_app_environment       = "qa"
paas_cf_space              = "bat-qa"
paas_web_app_memory        = 512
paas_web_app_instances     = 1
paas_postgres_service_plan = "small-11"
paas_redis_service_plan    = "micro-5_x"

# KeyVault
key_vault_resource_group    = "s121d01-shared-rg"
key_vault_name              = "s121d01-shared-kv-01"
key_vault_app_secret_name   = "APPLY-APP-SECRETS-QA"
key_vault_infra_secret_name = "BAT-INFRA-SECRETS-QA"

# StatusCake
statuscake_alerts = {
  apply-qa = {
    website_name   = "Apply-Teacher-Training-QA"
    website_url    = "https://qa.apply-for-teacher-training.service.gov.uk/integrations/monitoring/all"
    test_type      = "HTTP"
    check_rate     = 30
    contact_group  = [188603]
    trigger_rate   = 0
    node_locations = ["UKINT", "UK1", "MAN1", "MAN5", "DUB2"]
  }
  apply-cloudapps-qa = {
    website_name   = "Apply-Teacher-Training-Cloudapps-QA"
    website_url    = "https://apply-qa.london.cloudapps.digital/integrations/monitoring/all"
    test_type      = "HTTP"
    check_rate     = 30
    contact_group  = [188603]
    trigger_rate   = 0
    node_locations = ["UKINT", "UK1", "MAN1", "MAN5", "DUB2"]
  }
}
