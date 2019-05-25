
### Compute expected retirement in HFCS wave 2

# In P files:
# PE1100 at what age expect to retire:
# At what age do (you/he/she) plan(s) to stop working for pay?
# Filtering: IF((PE0100a<>5) and (PE0100a<>6) and (PE0900<>2))

# Other relevant variables
# RA0300 age
# PA0200 highest level of education completed
# PE0100x labour status
# PE0200 status in employment
# PE0300 job description / ISCO
# PE0400 main employment - NACE


# Housekeeping
using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using CategoricalArrays

file_in = "/Users/main/OneDrive - Istituto Universitario Europeo/data/HFCS/files/HFCS_UDB_2_1_ASCII/P1.csv";

df = DataFrame(CSV.read(file_in));

# Subset data
df_ind = df[:, [:SA0100, :RA0300, :PE1100]];

# Drop missing
df_ind2 = dropmissing(df_ind, disallowmissing=true);








# Keep year 2017 (earned income refers to last 12 months)
df_ind_2017 = df_ind[df_ind[:YEAR] .== 2017, :];

# Clean earned income variable
df_ind_2017 = df_ind_2017[df_ind_2017[:AGE] .> 15, :];          # Keep only working age population
df_ind_2017 = df_ind_2017[df_ind_2017[:AGE] .< 64, :];          # Keep only working age population
df_ind_2017[:INCEARN] = recode(df_ind_2017[:INCEARN], 0000000 => 0, 0000001 => 1); # Recoode no and 1 USD earnings
df_ind_2017 = df_ind_2017[df_ind_2017[:INCEARN] .< 9999999, :];         # Drop N/A (9999999 = N/A)
df_ind_2017 = df_ind_2017[df_ind_2017[:INCEARN] .> 0, :];              # Drop negative and zero earned incomes


# Compute sum stats
df_ind_2017_stats = by(df_ind_2017, [:YEAR, :STATENAME], [:INCEARN, :PERWT] =>
        x -> ( mean = mean(x.INCEARN, weights(x.PERWT)), mean_unweighted = mean(x.INCEARN), median = median(x.INCEARN, weights(x.PERWT)), median_unweighted = median(x.INCEARN), std = std(x.INCEARN, weights(x.PERWT)), N = length(x.INCEARN), gini = gini(x.INCEARN) ));

# Sort by median income and add as new variable
sort!(df_ind_2017_stats, :median_unweighted);
df_ind_2017_stats[:median_rank] = 1:size(df_ind_2017_stats, 1);
df_ind_2017_stats[:STATENAME_CATEG] = categorical(df_ind_2017_stats.STATENAME)

# Order main data according to unweighted median
df_ind_2017[:STATENAME_CATEG] = categorical(df_ind_2017.STATENAME)
df_2017 = join(df_ind_2017, df_ind_2017_stats, on = :STATENAME, makeunique=true  )
sort!(df_2017, :median_rank);

# Divide INCEARN by 1000
df_2017[:INCEARN] = df_2017.INCEARN .* 1/1000;
df_ind_2017_stats[:mean] = df_ind_2017_stats.mean .* 1/1000;
df_ind_2017_stats[:mean_unweighted] = df_ind_2017_stats.mean_unweighted .* 1/1000;
df_ind_2017_stats[:median] = df_ind_2017_stats.median .* 1/1000;
df_ind_2017_stats[:median_unweighted] = df_ind_2017_stats.median_unweighted .* 1/1000;


# Plot
@df df_2017 boxplot(:median_rank, :INCEARN,
title="State Individual Earned Income Distributions in 2017",
yaxis="current USD (thousands)",
notch=false,    # Bool. Notch the box plot? (false)
range=1.5,      # Real. Values more than range*IQR below the first quartile or above the third quartile are shown as outliers (1.5)
outliers=false, # Bool. Show outliers? (true)
whisker_width=:match, # Real or Symbol. Length of whiskers (:match)
xticks = ([0.5:1:51.5;], df_ind_2017_stats.STATENAME_CATEG),
xrotation=90,
tickfont=font(6),
xgrid = false,
legend = :topleft,
label =  "Unweighted distribution",
xlims = (0,52),
ylims = (0,220),
yticks = ([0:20:220;]),
tick_direction = :out,
left_margin = 0mm,
bottom_margin = 18mm)

@df df_ind_2017_stats scatter!(:median_rank, :median,
markershape = :x,
markersize = 2,
c = :black,
xlims = (0,52),
ylims = (0,220),
background_color_legend = false,
fg_legend = :transparent,
label = "Weighted median")

@df df_ind_2017_stats scatter!(:median_rank, :mean_unweighted,
markersize = 3,
c = :green,
xlims = (0,52),
ylims = (0,220),
background_color_legend = false,
fg_legend = :transparent,
label = "Unweighted mean")

@df df_ind_2017_stats scatter!(:median_rank, :mean,
markersize = 3,
c = :orange,
xlims = (0,52),
ylims = (0,220),
background_color_legend = false,
fg_legend = :transparent,
label = "Weighted mean")

savefig(graph_out)

# Save data
CSV.write(file_sumstats_out, df_ind_2017_stats)
# CSV.write(file_data_out, df_2017) - creates a large file
