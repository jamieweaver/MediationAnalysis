library(MediationAnalysis)

folder <- "G:/MediationAnalysis"
ssList <- list()
msList <- list()

ssList[[length(ssList) + 1]] <- createSimulationSettings(n = 1000,
                                                         nX = 8,
                                                         hCensor = 0.1,
                                                         aIntercept = log(0.5),
                                                         aX = c( 1, -1, 1, -1, 0, 0, 0, 0),
                                                         mIntercept = log(0.1),
                                                         mX = c(0, 0, 0.5, -1, 1.5, -1, 0, 0),
                                                         mA = log(2),
                                                         yIntercept = log(0.05),
                                                         yX = c(0.5, 0, 0.5, 0, -1, 0, 0, 0),
                                                         yA = log(0.5),
                                                         yM = log(1.5))

msList[[length(msList) + 1]] <- createModelsettings(ps = "oracle",
                                                    mrs = "oracle",
                                                    psAdjustment = "matching", 
                                                    mrsAdjustment = "model", 
                                                    mediatorType = "time-to-event")

msList[[length(msList) + 1]] <- createModelsettings(ps = "fit",
                                                    mrs = "fit",
                                                    psAdjustment = "matching", 
                                                    mrsAdjustment = "model", 
                                                    mediatorType = "time-to-event")

runSetOfSimulations(folder = file.path(folder, "methodVariation"), 
                    simulationSettingsList = ssList, 
                    modelSettingsList = msList,
                    nSimulations = 1000,
                    maxCores = 4)



# testing


simulationSettings <- createSimulationSettings()
data <- simulateData(simulationSettings)


modelSettings <- createModelsettings(ps = "oracle",
                                     mrs = "oracle",
                                     psAdjustment = "matching", 
                                     mrsAdjustment = "model", 
                                     mediatorType = "binary")

fitModel(data, modelSettings)








