# Do this in jupyter
# Sharpen your skills really well. Try to get internships in big companies from now itself

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder, MinMaxScaler
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer

from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.ensemble import ExtraTreesClassifier

from sklearn.metrics import accuracy_score, confusion_matrix, classification_report, f1_score

df = pd.read_csv("US_Heart_Patients.csv")
temp = df.copy()

X = temp.drop('Heart-Att', axis = 1)
y = df['Heart-Att'].values

# In any model, if the column is not important at all, then drop all those features


numeric_pipeline = Pipeline(steps=[
    ('impute', SimpleImputer(strategy='mean')),
    ('scale', MinMaxScaler())
])

categorical_pipeline = Pipeline(steps=[
    ('impute', SimpleImputer(strategy='most_frequent')),
    ('one-hot', OneHotEncoder(handle_unknown='ignore', sparse_output=False))
])

# Why we are not giving it as 1, 2 or 3 (Scalar Encoding)? The value of 3 is greater than 1 so the model will think it has more weightage

numerical_features = ['Age', 'CigsPerDay', 'Tot cholesterol', 'Systolic BP', 'Diastolic BP', 'BMI', 'HeartRate', 'Glucose']
categorical_features = ['Gender']

full_processor = ColumnTransformer(transformers=[
    ('number', numeric_pipeline, numerical_features),
    ('category', categorical_pipeline, categorical_features)
])

X_train, X_valid, y_train, y_valid = train_test_split(X, y, test_size=.3, random_state=34)

# numeric_pipeline.fit_transform(X_train.select_dtypes(include='number'))

# Why 100? If 70 can do the same work, then why do we use 100. With what value is it giving best accuracy
# Underfitting and Overfitting the model
# Understand how the model works (Bagging and Boosting)
# Find the meaning of parameters

# Leaves depends on number of features in your data
# Think logically for how the parameters need to be
clf = RandomForestClassifier(n_estimators=100, max_depth=3, random_state=0, min_samples_leaf = 7, min_samples_split = 10)
etc = ExtraTreesClassifier(random_state=0, n_estimators=100, max_depth=3)

RF_Pipeline = Pipeline(steps=[
    ('preprocess', full_processor),
    ('model', clf)
])

ET_Pipeline = Pipeline(steps=[
    ('preprocess', full_processor),
    ('model', etc)
])

# Try to do everything in Jupyter notebook (Different parameters, Accuracy etc). It is easy to see each and every step in the notebook (Sequentially)
clf_trained = RF_Pipeline.fit(X_train, y_train)
etc_trained = ET_Pipeline.fit(X_train, y_train)

preds_1 = RF_Pipeline.predict(X_valid)
preds_2 = ET_Pipeline.predict(X_valid)

acc_1 = accuracy_score(y_valid, preds_1)
acc_2 = accuracy_score(y_valid, preds_2)

f1_1 = f1_score(y_valid, preds_1, average = 'weighted')
f1_2 = f1_score(y_valid, preds_2, average = 'weighted')

# print(classification_report(y_valid, preds_1))
# print(confusion_matrix(y_valid, preds_1))

print("\n")
print(acc_1, acc_2) # For very clean data, you should try to get 90%+ accuracy
print("\n")
print(f1_1, f1_2)

print(RF_Pipeline.score(X_valid, y_valid), end = " ")
print(ET_Pipeline.score(X_valid, y_valid))

print("\n\n\n")
################################################################
# Feature Importance
'''
import matplotlib.pyplot as plt

plt.rcParams.update({'figure.figsize': (12.0, 8.0)})
plt.rcParams.update({'font.size': 14})

sorted = clf_trained.feature_importances_.argsort()
plt.barh(X.columns.values.tolist()[sorted], clf_trained.feature_importances_[sorted])
'''



################################################################
# Using Hyperparameter Tuning
'''
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import cross_val_score

param_grid = {
    'bootstrap': [True],
    'max_depth': [80, 90, 100, 110],
    'max_features': [2, 3],
    'min_samples_leaf': [3, 4, 5],
    'min_samples_split': [8, 10, 12],
    'n_estimators': [100, 200, 300, 1000]
}

search = GridSearchCV(RF_Pipeline, param_grid = param_grid, cv = 3, n_jobs = -1, verbose = 2, return_train_score = True)
_ = search.fit(X_train, y_train)

print('Best score:', abs(search.best_score_))
print('Best Params:', search.best_params_)
'''