library(ggplot2)
library(tidyverse)
library(blandr)
library(cowplot)
library(magrittr)
library(kableExtra)
library(gridExtra)
  #also need to run blandr2 'package' elements - not ready as a full package yet

getwd()
setwd("/Users/gregggriffenhagen/Dropbox/CO Validation Study/Data")
codata <- read.csv("co_data.csv")
head(codata); str(codata)
setwd("/Users/gregggriffenhagen/Dropbox/CO Validation Study/Images")

  #start by plotting the overall data based on where the measurements were obtained
p1 <- codata %>%
  mutate(iqr_ool = case_when(iq_r > td*1.3 ~ "Y",                               #want to have 2 separate shapes for data inside and outside of a range
                                      iq_r < td*0.7 ~ "Y",                      #this creates another variable to change shape
                                      iq_r <= td*1.3 ~ "N")) %>%
  ggplot(aes(x=td, y=iq_r, shape=iqr_ool, size = iqr_ool))
p1a <- p1 + geom_point(position = "jitter") +
  geom_abline(intercept = 0, slope = 1) +
  geom_abline(intercept = 0, slope = 1.3, linetype = "dashed") +                #the lines indicate a 30% deviation from unity
  geom_abline(intercept = 0, slope = 0.7, linetype = "dashed") +
  labs(x = "TD CO (L/min)",
       y= "HS-IQ CO (L/min)") +
  theme_bw() +
  theme(legend.position = "none") +
  scale_shape_manual(values = c(19,1)) +
  scale_size_manual(values = c(2.5,2)) +
  lims(y=c(1,5)) +
  annotate(geom="text", x=0.7, y=4.7, label="A", size = 12)# +
  #ggtitle("Thermodilution vs. HS-IQ - Radial Artery")
ggsave("TDvIQ_radial.png")

p2 <- codata %>% mutate(iqm_ool = case_when(iq_m > td*1.3 ~ "Y",
                                            iq_m < td*0.7 ~ "Y",
                                            iq_m <= td*1.3 ~ "N")) %>%
  ggplot(aes(x=td, y=iq_m, shape=iqm_ool, size = iqm_ool))
p2a <- p2 + geom_point(position="jitter") +
  geom_abline(intercept = 0, slope = 1) +
  geom_abline(intercept = 0, slope = 1.3, linetype = "dashed") +
  geom_abline(intercept = 0, slope = 0.7, linetype = "dashed") +
  labs(x = "TD CO (L/min)",
       y= "HS-IQ CO (L/min)") +
  theme_bw() +
  theme(legend.position = "none") +
  scale_shape_manual(values = c(19,1)) +
  scale_size_manual(values = c(2.5,2)) +
  lims(y=c(1,5)) +
  annotate(geom="text", x=0.7, y=4.7, label="B", size = 12)# +
  #ggtitle("Thermodilution vs. IQ - Dorsal Metatarsal Artery")
ggsave("TDvIQ_metatarsal.png")

#arrange 2 figures for image
fig1 <- grid.arrange(p1a, p2a, ncol=2)
ggsave("Figure_1.png", fig1, width=8, height=4.5, units = "in", dpi=300)

p3 <- ggplot(data = codata, aes(x=iq_r, y=iq_m))
p3a <- p3 + geom_point() +
  geom_smooth(method = lm, linetype = 'dotdash', color = 'black') +
  geom_abline(intercept = 0, slope = 1) +
  theme_bw() +
  #ggtitle("Comparison of IQ CO Measurements","Radial vs. Dorsal Metatarsal Artery") +
  labs(x="HS-IQ CO - Radial Artery (L/min)", y="HS-IQ CO - Dorsal Metatarsal Artery (L/min)") +
  annotate(geom="text", x=1.35, y=4.6, label="C", size = 14)
ggsave("Figure_2.png", p3a)

  #need to combine figs 1 & 2 into new figure 1
fig1_new <- grid.arrange(p1a, p2a, p3a, ncol=3)
ggsave("Figure_1_new.png", fig1_new, width=8, height=3, units="in", dpi=500)

  #assess whether the measurements from the 2 sites were different overall
stats::t.test(codata$iq_r, codata$iq_m, paired=TRUE)
stats::cor.test(~iq_r+iq_m, data=codata, method="kendall", continuity=FALSE)

  #split into 2 datasets - one for radial measurements, one for metatarsal
codata_r <- codata %>%
  drop_na('iq_r') %$%
  blandr2.statistics(td, iq_r)                                                  #creates the BA statistics necessary for evaluation
                      
codata_r %$%
 length(method1)                                                                #check number of entries used for newly created dataframe
codata_r$no.of.observations                                                     #hopefully these match...

codata_m <- codata %>%                                                          #repeat for metatarsal measurements
  drop_na('iq_m') %$%  
  blandr2.statistics(td, iq_m)

codata_m %$%
  length(method1)
codata_m$no.of.observations

  #Bland Altman overall - radial artery
                                          
codata_r %>% blandr.plot.ggplot(td,iq_r, 
                                ciDisplay = F)                                  #without regression line - not used
                                             

BA_rad <- codata_r %>% blandr2.plot.ggplot(td,iq_r,                             #create BA plot for absolute bias
                                ciDisplay = F, 
                                plotRegression = T,
                                plotRegression.se = F) +                        #and with regression line
  theme_bw() +
  labs(x = "Mean CO (L/min)",
       y = "Difference Between Measurements (L/min)",
       title="") +                                                              #need to fremove autogenerated title
  annotate("rect", xmin = -Inf,                                                 #builds the bias CI grey box
           xmax = Inf,
           ymin = codata_r$biasLowerCI, 
           ymax = codata_r$biasUpperCI,
           fill = "grey", 
           alpha = 0.3) +
  annotate(geom="text", x=1, y=3.2, label="A", size=14)                         #add the figure notation
  #ggsave("BA_rad.png")
  #print(BA_rad)

BA_prop_rad <- codata_r %>%                                                     #create proportional bias plot
  blandr2.plot.ggplot(td,iq_r,
                      ciDisplay = F,
                      y.plot.mode = "proportion") +                             #plot proportional differences
  theme_bw() +
  geom_abline(intercept = c(30, -30),                                           #include 30% difference lines
              slope = 0,
              linetype = "twodash",
              size=1) +
  labs(x = "Mean CO (L/min)",
       y = "Difference Between Measurements (%)",
       title="") +                                                              #remove autogenerated title
  annotate(geom="text",                                                         #add figure marker for multiple plots
           x=1, y=90,
           label="A",
           size=14) +
  annotate("rect", xmin = -Inf,                                                 #add proportional bias CI box
           xmax = Inf, 
           ymin = codata_r$propBiasLowerCI, 
           ymax = codata_r$propBiasUpperCI,
           fill = "grey", 
           alpha = 0.3)
#ggsave("BA_prop_rad.png")

  #Checking normality of the differences
blandr.plot.qq(codata_r)
blandr.plot.normality(codata_r)                                                 #vaguely normal - some deviation at the extremes

  # Output variables of interest for tables
rad_art_overall <- codata_r[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                 "propBias", "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                 "no.of.observations")] %>%
  rbind() %>%
  unlist()

  #Bland Altman overall - metatarsal artery

codata_m %>% blandr.plot.ggplot(td,iq_m,                                        #same 2 plots for the metatarsal data
                                ciDisplay = F) #without regression line
                                               #not used

BA_meta <- codata_m %>%
  blandr2.plot.ggplot(td,iq_m,
                      ciDisplay = F,
                      plotRegression = T,
                      plotRegression.se = F) +
  theme_bw() +
  labs(x = "Mean CO (L/min)",
       y = "Difference Between Measurements (L/min)",
       title="") +
  annotate("rect",
           xmin = -Inf, 
           xmax = Inf,
           ymin = codata_m$biasLowerCI, 
           ymax = codata_m$biasUpperCI,
           fill = "grey", 
           alpha = 0.3) +
  annotate(geom="text", x=0.95, y=2.9, label="B", size=14)
#ggsave("BA_meta.png")

BA_prop_meta <- codata_m %>% blandr2.plot.ggplot(td,iq_m,
                                ciDisplay = F,
                                y.plot.mode = "proportion") +                   #plot proportional differences
  theme_bw() +
  geom_abline(intercept = c(30, -30),
              slope = 0,
              linetype = "dotted") +                                            #include 30% difference lines
  labs(x = "Mean CO (L/min)",
       y="Difference Between Measurements (%)",
       title="") +
  geom_abline(intercept = c(30, -30),
              slope = 0,
              linetype = "twodash",
              size=1) +                                                         #include 30% difference lines
  annotate(geom="text", x=0.9, y=80, label="B", size=14) +
  annotate("rect",
           xmin = -Inf, 
           xmax = Inf,
           ymin = codata_m$propBiasLowerCI, 
           ymax = codata_m$propBiasUpperCI,
           fill = "grey", 
           alpha = 0.3)
  #ggsave("BA_prop_meta.png")

  #Checking normality of the differences
blandr.plot.qq(codata_m)
blandr.plot.normality(codata_m)                                                 #these differences look slightly better

met_art_overall <- codata_m[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                              "propBias", "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                              "no.of.observations")] %>%
  rbind() %>%
  unlist()

  #create 2 overall BA figures
fig3 <- grid.arrange(BA_rad, BA_meta, ncol=2)
ggsave("Figure_3.png", fig3, width=8, height=4.5, units = "in", dpi=300)

fig4 <- grid.arrange(BA_prop_rad, BA_prop_meta, ncol=2)
ggsave("Figure_4.png", fig4, width=8, height=4.5, units = "in", dpi=300)


t1 <- rbind(rad_art_overall, met_art_overall) %>% round(digits = 3)
colnames(t1) <- c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
             "propBias", "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
             "no.of.observations")
#t1 <- t1[1:2, ]   Only needed to get rid of 'make.row.names' row that was added
kbl(t1, "latex", booktabs = T) %>%
  save_kable("overall.stats.pdf")
  
  #split data into time points for evaluation individually
  #time 1 = pre-hypotensive, time 2 = after hypotension induced, time 4 = after restoration of normotension

  #Normotensive state
datr1 <- codata %>% 
  drop_na('iq_r') %>%
  filter(time == 1) %$%
  blandr2.statistics(td, iq_r)

datm1 <- codata %>%
  drop_na('iq_m') %>%
  filter(time == 1) %$%
  blandr2.statistics(td, iq_m)

p4a <- datr1 %>% blandr.plot.ggplot(td, iq_r,
                                    ciDisplay = F,
                                    plotTitle = "") +
  theme_bw() +
  labs(x="", y="") +
  scale_y_continuous(limits = c(-4, 4)) +
  annotate("rect", xmin = -Inf, 
           xmax = Inf, ymin = datr1$biasLowerCI, 
           ymax = datr1$biasUpperCI, fill = "grey", 
           alpha = 0.3)
p4b <- datm1 %>% blandr.plot.ggplot(td, iq_m,
                                    ciDisplay = F,
                                    plotTitle = "") +
  theme_bw() +
  labs(x="", y="") +
  scale_y_continuous(limits = c(-4, 4)) +
  annotate("rect", xmin = -Inf, 
           xmax = Inf, ymin = datm1$biasLowerCI, 
           ymax = datm1$biasUpperCI, fill = "grey", 
           alpha = 0.3)
p4c <- plot_grid(p4a, p4b,
                 labels = c("radial", "metatarsal"),
                 label_fontface = "plain",
                 label_x = c(0.25, -.1)) +
   theme(plot.margin = margin(25, 0, 0, 0))

Fig5_base <- ggdraw(p4c) +
  draw_label("T1", y = 1, vjust = 2, fontface = "bold", size = 16)
ggsave("BA_baseline.png")
 # Grab stats output for table
radial_baseline <- datr1[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                           "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                              "no.of.observations")] %>%
  rbind() %>%
  unlist()
metatarsal_baseline <- datm1[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                               "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                           "no.of.observations")] %>%
  rbind() %>%
  unlist()

#hypotensive state
datr2 <- codata %>% 
  drop_na('iq_r') %>%
  filter(time == 2) %$%
  blandr2.statistics(td, iq_r)

datm2 <- codata %>%
  drop_na('iq_m') %>%
  filter(time == 2) %$%
  blandr2.statistics(td, iq_m)

p5a <- datr2 %>% blandr.plot.ggplot(td, iq_r,
                                    ciDisplay = F,
                                    plotTitle = "") +
  theme_bw() +
  labs(x="", y="") +
  scale_y_continuous(limits = c(-4, 4)) +
  annotate("rect", xmin = -Inf, 
           xmax = Inf, ymin = datr2$biasLowerCI, 
           ymax = datr2$biasUpperCI, fill = "grey", 
           alpha = 0.3)
p5b <- datm2 %>% blandr.plot.ggplot(td, iq_m,
                                    ciDisplay = F,
                                    plotTitle = "") +
  theme_bw() +
  labs(x="", y="") +
  scale_y_continuous(limits = c(-4, 4)) +
  annotate("rect", xmin = -Inf, 
           xmax = Inf, ymin = datm2$biasLowerCI, 
           ymax = datm2$biasUpperCI, fill = "grey", 
           alpha = 0.3)
p5c <- plot_grid(p5a, p5b,
                 labels = c("radial", "metatarsal"),
                 label_fontface = "plain",
                 label_x = c(0.25, -0.1)) +
  theme(plot.margin = margin(25, 0, 0, 0))

Fig5_hypo <- ggdraw(p5c) +
  draw_label("T2", y = 1, vjust = 2, fontface = "bold", size = 16)
ggsave("BA_hypotensive.png")
  #Grab stats data time point 2
radial_hypotensive <- datr2[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                              "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                           "no.of.observations")] %>%
  rbind() %>%
  unlist()
metatarsal_hypotensive <- datm2[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                                  "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                               "no.of.observations")] %>%
  rbind() %>%
  unlist()

  #after return to normotension time = 4
datr4 <- codata %>% 
  drop_na('iq_r') %>%
  filter(time == 4) %$%
  blandr2.statistics(td, iq_r)

datm4 <- codata %>%
  drop_na('iq_m') %>%
  filter(time == 4) %$%
  blandr2.statistics(td, iq_m)

p6a <- datr4 %>% blandr.plot.ggplot(td, iq_r,
                                    ciDisplay = F,
                                    plotTitle = "") +
  theme_bw() +
  labs(x="", y="") +
  scale_y_continuous(limits = c(-4, 4)) +
  annotate("rect", xmin = -Inf, 
                             xmax = Inf, ymin = datr4$biasLowerCI, 
                             ymax = datr4$biasUpperCI, fill = "grey", 
                             alpha = 0.3)
p6b <- datm4 %>% blandr.plot.ggplot(td, iq_m,
                                    ciDisplay = F,
                                    plotTitle = "") +
  theme_bw() +
  labs(x="", y="") +
  scale_y_continuous(limits = c(-4, 4)) +
  annotate("rect", xmin = -Inf, 
           xmax = Inf, ymin = datm4$biasLowerCI, 
           ymax = datm4$biasUpperCI, fill = "grey", 
           alpha = 0.3)
p6c <- plot_grid(p6a, p6b,
                 labels = c("radial", "metatarsal"),
                 label_fontface = "plain",
                 label_x = c(0.25, -0.1)) +
  theme(plot.margin = margin(25, 0, 0, 0))
p6c
Fig5_ret <- ggdraw(p6c) +
  draw_label("T4", y = 1, vjust = 2, fontface = "bold", size = 16)
ggsave("BA_after_transfusion.png")
  #Grab timepoint 4 stats
radial_after_transfusion <- datr4[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                                    "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                           "no.of.observations")] %>%
  rbind() %>%
  unlist()
metatarsal_after_transfusion <- datm4[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                                        "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                               "no.of.observations")] %>%
  rbind() %>%
  unlist()

Fig_5 <- grid.arrange(Fig5_base, Fig5_hypo, Fig5_ret, ncol=3,
                      left = textGrob("HS-IQ CO (L/min)", rot=90, gp=gpar(fontsize=15)),
                      bottom = textGrob("TD CO (L/min)", gp=gpar(fontsize=15)))
ggsave("Figure_5.png", Fig_5, width=8, height=4.5, units = "in", dpi=300)
pfinal <- add_sub(pfinal, "Mean CO", hjust = 1)
pfinal <- add_sub(pfinal, "Difference between techniques (L/min)", -0.05, 5, angle = 90)
ggdraw(pfinal)

t2 <- rbind(radial_baseline, metatarsal_baseline,
            radial_hypotensive, metatarsal_hypotensive,
            radial_after_transfusion, metatarsal_after_transfusion) %>% round(digits = 3)
colnames(t2) <- c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA", "propBias",
                  "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                  "no.of.observations")

kbl(t2, "latex", booktabs = T) %>%
  save_kable("individual.timepoint.stats.pdf")

radial_artery <- codata_r[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                              "propBias", "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                              "no.of.observations")] %>%
  rbind() %>%
  unlist()
metatarsal_artery <- codata_m[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                              "propBias", "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                              "no.of.observations")] %>%
  rbind() %>%
  unlist()
rad_baseline <- datr1[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                        "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                           "no.of.observations")] %>%
  rbind() %>%
  unlist()
NA_vector <- c(NA, NA, NA, NA, NA)
rad_baseline <- c(rad_baseline[1:5], NA_vector, as.integer(rad_baseline[6]))
met_baseline <- datm1[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                        "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                               "no.of.observations")] %>%
  rbind() %>%
  unlist()
met_baseline <- c(met_baseline[1:5], NA_vector, as.integer(met_baseline[6]))
rad_hypotensive <- datr2[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                           "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                              "no.of.observations")] %>%
  rbind() %>%
  unlist()
rad_hypotensive <- c(rad_hypotensive[1:5], NA_vector, as.integer(rad_hypotensive[6]))
met_hypotensive <- datm2[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                           "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                                  "no.of.observations")] %>%
  rbind() %>%
  unlist()
met_hypotensive <- c(met_hypotensive[1:5], NA_vector, as.integer(met_hypotensive[6]))
rad_transfusion <- datr4[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                           "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                                    "no.of.observations")] %>%
  rbind() %>%
  unlist()
rad_transfusion <- c(rad_transfusion[1:5], NA_vector, as.integer(rad_transfusion[6]))
met_transfusion <- datm4[c("bias", "biasUpperCI", "biasLowerCI", "upperLOA", "lowerLOA",
                           "propBiasUpperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                                        "no.of.observations")] %>%
  rbind() %>%
  unlist()
met_transfusion <- c(met_transfusion[1:5], NA_vector, as.integer(met_transfusion[6]))
t3 <- rbind(radial_artery, metatarsal_artery,
            rad_baseline, met_baseline,
            rad_hypotensive, met_hypotensive,
            rad_transfusion, met_transfusion) %>%
           as.data.frame() %>%
  round(3)

colnames(t3) <- c("Bias", "Bias UpperCI", "bias LowerCI", "upper LOA", "lower LOA",
                  "Proportional bias", "Proportional bias upperCI", "propBiasLowerCI", "propUpperLOA", "propLowerLOA",
                  "no.of.observations")
#t1 <- t1[1:2, ]   Only needed to get rid of 'make.row.names' row that was added
options(knitr.kable.NA = "")
kbl(t3, "latex", booktabs = T) %>%
  save_kable("overall.stats.alt.3.pdf")

