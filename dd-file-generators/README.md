# Things that we want to be able to specify

ets_cap YEAR VALUE // Limits the traded sector cap in a year to a value

total_cap YEAR VALUE // Limits the total emissions in a year to a value

carbon_budget YEAR VALUE // Limits the total emissions in a year to the value / 5

territorial_from YEAR // From that year, removes ets_target caps and non-ets caps as well (this MUST be set after ets_target and total_target) and then duplicates total_caps that are NET to their equivalent TER version.

remaining_ias_from YEAR // From that year, duplicates any ets_target and total_target to create a second set of constraints that include IAS (this must be set last)



We always constrain the non-IAS target, even we are constraining the with-IAS target, so as to make a smoother transition on interpolation.


Year in which remaining international aviation and shipping is included in the carbon budgets

Note:

* Some international aviation and shipping is already included, because it is already part of the EU ETS
* May be problems with interpolating, if it is included in a year where we haven't set a budget


A territorial emissions target

Separate traded and non traded emissions targets

* The non-traded target is assumed to be the total target, less the traded target
* If you set a territorial emissions targets, then the traded target is not enforced




