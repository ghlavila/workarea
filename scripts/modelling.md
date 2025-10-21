## Modelling: Final Evaluation and Code Change Recommendations

### Absolutely necessary
These prevent runtime errors or incorrect/biased results.

- Fix `AutogluonWrapper.predict_proba` (avoid globals; ensure correct shape)
  ```python
def predict_proba(self, X):
    if isinstance(X, pd.Series):
        X = X.values.reshape(1, -1)
    if not isinstance(X, pd.DataFrame):
        X = pd.DataFrame(X, columns=self.feature_names)
    preds = self.ag_model.predict_proba(X, as_multiclass=True)
    if self.ag_model.problem_type == "regression" or self.target_class is None:
        return preds
    return preds[self.target_class]
  ```

- Replace invalid SHAP call
  ```python
# was: shap.KernelExplainer(..., algorithm="tree")  # invalid
explainer = shap.Explainer(ag_wrapper.predict_proba, baseline)
shap_values = explainer(X_test)
  ```

- Remove invalid scoring method
  ```python
# delete this line in model_score
# predictor.compile()
  ```

- Remove fabricated “empty” training row (and do not use as SHAP background)
  ```python
# delete in model_train
# empty_row = {label: 0}
# data_set.loc[len(data_set)] = empty_row
  ```

### Somewhat useful
These improve reliability, stability, and performance without being strictly required to run.

- Do not force `dtype="str"` in scoring; let pandas infer
  ```python
reader = pd.read_csv(args.input_file, delimiter=",", chunksize=args.batch_size)
  ```

- Use a representative SHAP background (small and real)
  ```python
baseline = shap.kmeans(X_train[y_train == negative_class], 50)
  ```

- Stratified, reproducible splits (pre- and post-pruning)
  ```python
train_data, test_data = train_test_split(
    data_set, test_size=0.25, stratify=data_set[label], random_state=42
)
  ```

- Reduce feature-importance workload in fast mode
  ```python
fi_kwargs = (
    dict(subsample_size=2000, num_shuffle_sets=5)
    if args.fast_mode
    else dict(subsample_size=5000, num_shuffle_sets=10)
)
top_features = predictor.feature_importance(data=test_data, **fi_kwargs)
  ```

- Reproducible SHAP sampling
  ```python
X_test = pd.DataFrame(test_data.drop(columns=[label])).sample(sample_size, random_state=42)
  ```

### Minimal
These are small hygiene or convenience changes with low impact on correctness/performance.

- Avoid duplicate plot filename overwrite
  ```python
plt.savefig(f"{model_dir}/heatmap_top1000.png", bbox_inches="tight", transparent=True)
  ```

- Drop `mpid` before scoring (and avoid extra conversions)
  ```python
mpids = batch.get("mpid")
features_df = batch.drop(columns=["mpid"], errors="ignore")
scores = predictor.predict_proba(features_df, as_multiclass=False)
out_df = pd.concat([mpids, scores], axis=1)
out_df.to_csv(args.output_file, index=False, header=False, mode="a", float_format="%.3f")
  ```

- Pass the DataFrame directly at scoring time; do not wrap in `TabularDataset`.