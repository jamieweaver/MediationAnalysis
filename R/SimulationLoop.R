# Copyright 2023 Observational Health Data Sciences and Informatics
#
# This file is part of MediationAnalysis
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# library(dplyr)

#' Run a set of simulations
#'
#' @param folder                 Folder to write (intermediate) results.
#' @param simulationSettingsList A list of simulation settings objects as created
#'                               by `createSimulationSettings()`.
#' @param modelSettingsList      A list of model fitting settings as created by
#'                               `createModelSettings()`.
#' @param nSimulations           Number of times to repeat each simulation
#' @param maxCores               Maximum number of CPU cores to use at the same 
#'                               time.
#'
#' @return
#' Does not return anything. Writes results to the folder.
#' 
#' @export
runSetOfSimulations <- function(folder, 
                                simulationSettingsList, 
                                modelSettingsList,
                                nSimulations = 1000,
                                maxCores = 4) {
  if (!dir.exists(folder)) {
    dir.create(folder, recursive = TRUE)
  }
  cluster <- ParallelLogger::makeCluster(maxCores)
  on.exit(ParallelLogger::stopCluster(cluster))
  allResults <- list()
  nScenarios <- length(simulationSettingsList) * length(modelSettingsList)
  i <- 1
  # ParallelLogger::clusterRequire(cluster, "MediationAnalysis")
  # simulationSettings = simulationSettingsList[[1]]
  # modelSettings = modelSettingsList[[1]]
  for (simulationSettings in simulationSettingsList) {
    for (modelSettings in modelSettingsList) {
      message(sprintf("Running scenario %d of %d", i, nScenarios))
      fileName <- file.path(folder, 
                            sprintf("result_%s.rds", 
                                    digest::digest(list(modelSettings, simulationSettings))))
      if (file.exists(fileName)) {
        summaryResults <- readRDS(fileName)
      } else {
        results <- ParallelLogger::clusterApply(cluster, 
                                                seq_len(nSimulations), 
                                                runOneSimulation, 
                                                simulationSettings = simulationSettings,
                                                modelSettings = modelSettings)
        results <- results %>%
          bind_rows()
        summaryResults <- tibble(
          coverageMainEffect = mean(simulationSettings$yA >= results$mainLogLb & 
                                      simulationSettings$yA <= results$mainLogUb),
          coverageMediatorEffect = mean(simulationSettings$yM >= results$mediatorLogLb & 
                                          simulationSettings$yM <= results$mediatorLogUb),
          coverageMainEffectNoM = mean(simulationSettings$yA >= results$mainLogLb & 
                                         simulationSettings$yA <= results$mainLogUb),
          coverageIndirectEffect = mean(log(1) >= results$mainLogLbDiff & log(1) <= results$mainLogUbDiff), # wrong?
          meanMainEffect = mean(results$mainLogHr),
          meanMediatorEffect = mean(results$mediatorLogHr),
          meanMainEffectNoM = mean(results$mainLogHrNoM),
          meanIndirectEffect = mean(results$mainLogDiff)
        )
        simulationSettings$aX <- paste(simulationSettings$aX, collapse = ", ")
        simulationSettings$mX <- paste(simulationSettings$mX, collapse = ", ")
        simulationSettings$yX <- paste(simulationSettings$yX, collapse = ", ")
        summaryResults <- summaryResults %>% 
          bind_cols(as_tibble(modelSettings)) %>%
          bind_cols(as_tibble(simulationSettings))
        saveRDS(summaryResults, fileName)
      }
      allResults[[i]] <- summaryResults
      i <- i + 1
    }
  }
  allResults <- bind_rows(allResults)
  readr::write_csv(allResults, file.path(folder, "Results.csv"))
}

runOneSimulation <- function(seed, simulationSettings, modelSettings) {
  set.seed(seed)
  data <- simulateData(simulationSettings)
  estimates <- fitModel(data, modelSettings)
  return(estimates)
}
