// Copyright 2022 Webb Technologies Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
use std::ops;
use std::sync::Arc;
use std::time::Duration;

use webb::evm::contract::tornado::TornadoContract;
use webb::evm::contract::tornado::TornadoContractEvents;
use webb::evm::ethers::contract::LogMeta;
use webb::evm::ethers::prelude::*;
use webb::evm::ethers::providers;
use webb::evm::ethers::types;

use crate::config;
use crate::store::sled::SledStore;
use crate::store::LeafCacheStore;

#[derive(Copy, Clone, Debug)]
pub struct TornadoLeavesWatcher;
/// Represents a Tornado leaves watcher.
#[derive(Clone, Debug)]
pub struct TornadoContractWrapper<M: Middleware> {
    config: config::TornadoContractConfig,
    contract: TornadoContract<M>,
}

impl<M: Middleware> TornadoContractWrapper<M> {
    /// Creates a new TornadoContractWrapper.
    pub fn new(config: config::TornadoContractConfig, client: Arc<M>) -> Self {
        Self {
            contract: TornadoContract::new(config.common.address, client),
            config,
        }
    }
}

impl<M: Middleware> ops::Deref for TornadoContractWrapper<M> {
    type Target = Contract<M>;

    fn deref(&self) -> &Self::Target {
        &self.contract
    }
}

impl<M: Middleware> super::WatchableContract for TornadoContractWrapper<M> {
    fn deployed_at(&self) -> types::U64 {
        self.config.common.deployed_at.into()
    }

    fn polling_interval(&self) -> Duration {
        Duration::from_millis(self.config.events_watcher.polling_interval)
    }

    fn max_events_per_step(&self) -> types::U64 {
        self.config.events_watcher.max_events_per_step.into()
    }

    fn print_progress_interval(&self) -> Duration {
        Duration::from_millis(
            self.config.events_watcher.print_progress_interval,
        )
    }
}

#[async_trait::async_trait]
impl super::EventWatcher for TornadoLeavesWatcher {
    const TAG: &'static str = "Tornado Watcher For Leaves";

    type Middleware = providers::Provider<providers::Http>;

// Q3. Webb

/* [Infrastructure Track Only] Explain how the relayer works for the deposit part of the tornado contract */


    type Contract = TornadoContractWrapper<Self::Middleware>;

    type Events = TornadoContractEvents;

    type Store = SledStore;

    #[tracing::instrument(skip_all)]
    async fn handle_event(
        &self, // Referencing the current module.
        store: Arc<Self::Store>,   // Define the store of the current module and share its ownership within the module. 
        contract: &Self::Contract, // Define variable "contract" and refrence it to the current module,
                                   // give it the bath to TornadoContractWrapper Contract
        (event, log): (Self::Events, LogMeta), // Assigning "event" to Events type of TornadoContractEvents 
                                              // of the current module, and log LogMeta of webb evm ethers immp. 
    ) -> anyhow::Result<()> {
        match event {
            TornadoContractEvents::DepositFilter(deposit) => {
            // Bind the deposit commitment to "commitment" variable
                let commitment = deposit.commitment;
            // Bind the deposit leaf index to "leaf_index" variable
                let leaf_index = deposit.leaf_index;
            // Create a new fixed-hash with 32 bytes (256 bits) size from slice "&commitment" 
            // but passing a refernce to it,
            // along side with the leaf_index of the depositor, and assign it to variable "value"
                let value = (leaf_index, H256::from_slice(&commitment));
            // Before binding value of the chain ID to variable "chain_id" the ".await" keyword "pause",
            // and checks log of block number for contract address & value deposited and then 
            // return control to the runtime and match the event TornadoContractEvents for inserting leaves
                let chain_id = contract.client().get_chainid().await?;  
                store
                    .insert_leaves((chain_id, contract.address()), &[value])?;
                    // If the block number suffice insert the last deposit block number aganist both
                    // chain ID & contract Address into store
                store.insert_last_deposit_block_number(
                    (chain_id, contract.address()),
                    // Wait for the block number log
                    log.block_number,
                )?;
            // collect structured, event-based diagnostic information
                tracing::debug!(
                    "Saved Deposit Event ({}, {})",
                    value.0,
                    value.1
                );
            }
            TornadoContractEvents::WithdrawalFilter(_) => {
                // we don't care for withdraw events for now
            }
        };

        Ok(())
    }
}
