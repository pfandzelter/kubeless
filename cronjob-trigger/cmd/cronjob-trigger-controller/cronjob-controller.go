/*
Copyright (c) 2016-2017 Bitnami

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/kubeless/cronjob-trigger/pkg/controller"
	cronjobtriggerutils "github.com/kubeless/cronjob-trigger/pkg/utils"
	"github.com/kubeless/cronjob-trigger/pkg/version"
	kubelessutils "github.com/kubeless/kubeless/pkg/utils"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "cronjob-trigger-controller",
	Short: "Kubeless cronjob trigger controller",
	Long:  "Kubeless cronjob trigger controller",
	Run: func(cmd *cobra.Command, args []string) {

		kubelessClient, err := kubelessutils.GetFunctionClientInCluster()
		if err != nil {
			logrus.Fatalf("Cannot get kubeless CR API client: %v", err)
		}

		cronjobTriggerClient, err := cronjobtriggerutils.GetFunctionClientInCluster()
		if err != nil {
			logrus.Fatalf("Cannot get Cronjob trigger API client: %v", err)
		}

		cronJobTriggerCfg := controller.CronJobTriggerConfig{
			KubeCli:        cronjobtriggerutils.GetClient(),
			TriggerClient:  cronjobTriggerClient,
			KubelessClient: kubelessClient,
		}

		cronJobTriggerController := controller.NewCronJobTriggerController(cronJobTriggerCfg)

		stopCh := make(chan struct{})
		defer close(stopCh)

		go cronJobTriggerController.Run(stopCh)

		sigterm := make(chan os.Signal, 1)
		signal.Notify(sigterm, syscall.SIGTERM)
		signal.Notify(sigterm, syscall.SIGINT)
		<-sigterm
	},
}

func main() {
	logrus.Infof("Running Kubeless cronjob trigger controller version: %v", version.Version)
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
