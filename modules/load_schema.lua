local api_loader = require('api_loader')
local validator = require('schema_validation')

local module = { }
if (not module.mob_schema) then 
module.mob_schema = validator.CreateSchemaValidator(api_loader.init("data/MOBILE_API.xml"))
end
if (not module.hmi_schema) then
module.hmi_schema = validator.CreateSchemaValidator(api_loader.init("data/HMI_API.xml", true))
end
return module