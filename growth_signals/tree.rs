use anyhow::{Context, Result};
use clap::Args;
use query_engine::query::{Field, ValueVersion};
use query_engine::select_tree::{TreeGroup, TreeNode};
use query_engine::table::Table;
use serde_json::{from_reader, to_string_pretty};
use std::collections::{BTreeMap, HashMap};
use std::fs::File;
use tracing::{error, info};

#[derive(Args)]
pub struct TreeArgs {
    /// Table json to read
    #[arg(short, long)]
    table: String,

    /// Lookup table for popsycle IAB categories (json map)
    #[arg(short, long)]
    lookup: String,
}

impl TreeArgs {
    pub fn run(&self) -> Result<()> {
        // open our table file
        let f = File::open(&self.table).context("Unable to open table file")?;

        // read it to a table
        let table: Table = from_reader(f).context("Error parsing table file")?;

        // open our lookup table
        let f = File::open(&self.lookup).context("Unable to open lookup file")?;

        // and store it in a hashmap
        let lookup: HashMap<String, String> =
            from_reader(f).context("Error parsing lookup table")?;

        // start off with our root node
        let mut root_node = TreeGroup {
            id: "growth-signals".to_string(),
            label: "Growth Signals".to_string(),
            help_text: "Behavioral intent data sourced daily from internet traffic".to_string(),
            ..Default::default()
        };

        let mut categories: BTreeMap<u32, BTreeMap<String, String>> = BTreeMap::new();
        for select in &table.selects {
            if !select.id.starts_with("IAB") {
                info!("Ignoring select {}", select.id);
                continue;
            }
            // parse out higher level number
            // and store all the ids in sorted top level by category, sub level by label
            if let Some((iab, _)) = select.id.strip_prefix("IAB").unwrap().split_once('-') {
                if let Ok(iab_num) = iab.parse::<u32>() {
                    categories
                        .entry(iab_num)
                        .and_modify(|e| {
                            e.insert(select.label.clone(), select.id.clone());
                        })
                        .or_insert_with(|| {
                            let mut b = BTreeMap::new();
                            b.insert(select.label.clone(), select.id.clone());
                            b
                        });
                } else {
                    error!("Unable to parse IAB category from {iab} - ignoring");
                }
            } else if let Some((iab, _)) = select.id.strip_prefix("IAB").unwrap().split_once('_') {
                if let Ok(iab_num) = iab.parse::<u32>() {
                    categories
                        .entry(iab_num)
                        .and_modify(|e| {
                            e.insert(select.label.clone(), select.id.clone());
                        })
                        .or_insert_with(|| {
                            let mut b = BTreeMap::new();
                            b.insert(select.label.clone(), select.id.clone());
                            b
                        });
                } else {
                    error!("Unable to parse IAB category from {iab} - ignoring");
                }
            } else {
                error!("Unable to parse IAB category from {} - ignoring", select.id);
            }
        }

        // construct a node for each used high level category
        for (cat, selects) in categories {
            let id = format!("IAB{cat}");
            let label = if let Some(c) = lookup.get(&id) {
                c.clone()
            } else {
                format!("IAB Category {cat}")
            };
            info!("Adding tree node for category {cat}, {label}");
            let help_text = format!("IAB OpenRTB 2.4 category {cat}");
            let mut node = TreeGroup {
                id,
                label,
                help_text,
                ..Default::default()
            };
            // add selects that we have
            for (_, id) in selects {
                let f = Field {
                    table_id: table.id.clone(),
                    select_id: id,
                    table_node: None,
                    version: ValueVersion::Latest,
                };
                node.members.push(TreeNode::Select(f));
            }
            root_node.members.push(TreeNode::Group(node));
        }

        println!("{}", to_string_pretty(&root_node)?);

        Ok(())
    }
}