# List of hardware profiles

# VoCore
$(eval $(call GluonProfile,VOCORE))
$(eval $(call GluonProfileFactorySuffix,VOCORE))
$(eval $(call GluonModel,VOCORE,vocore,vocore))

$(eval $(call GluonProfile,DIR615H1))
$(eval $(call GluonModel,DIR615C1,dir-615-h1,d-link-dir-615-rev-h1))
