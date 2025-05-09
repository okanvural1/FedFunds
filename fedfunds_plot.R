# =============================================
# Federal Funds Rate vs 30-Year Mortgage Rate (Final)
# =============================================

# 1. Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, fredr, lubridate, scales, ggthemes)

# 2. Set API key (replace with your key)
fredr_set_key("6bf8aa2b912c77f02d2dbdbd03360a38") 

# 3. NBER recession periods
recession_periods <- data.frame(
  start = as.Date(c("1957-08-01", "1960-04-01", "1969-12-01",
                   "1973-11-01", "1980-01-01", "1981-07-01",
                   "1990-07-01", "2001-03-01", "2007-12-01",
                   "2020-02-01")),
  end = as.Date(c("1958-04-01", "1961-02-01", "1970-11-01",
                 "1975-03-01", "1980-07-01", "1982-11-01",
                 "1991-03-01", "2001-11-01", "2009-06-01",
                 "2020-04-01"))
)

# 4. Fetch data
fed_data <- fredr(
  series_id = "FEDFUNDS",
  observation_start = as.Date("1971-04-01"),
  observation_end = Sys.Date()
) %>% 
  mutate(series = "Federal Funds Rate")

mortgage_data <- fredr(
  series_id = "MORTGAGE30US",
  observation_start = as.Date("1971-04-01"),
  observation_end = Sys.Date()
) %>% 
  mutate(series = "30-Year Mortgage Rate")
commercial_paper <- fredr(
  series_id = "DCPF3M",  # FRED code for 90-Day AA Financial Commercial Paper
  observation_start = as.Date("1971-04-01"),
  observation_end = Sys.Date()
) %>% 
  mutate(series = "90-Day Commercial Paper")

# 5. Combine data
combined_data <- bind_rows(fed_data, mortgage_data) %>% 
  mutate(date = as.Date(date))

# 6. Create plot with perfect title spacing
ggplot() +
  # Recession shading
  geom_rect(
    data = recession_periods %>% filter(start >= as.Date("1970-01-01")),
    aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
    fill = "gray80", alpha = 0.3
  ) +
  
  # Rate lines (blue/red theme)
  geom_line(
    data = combined_data,
    aes(x = date, y = value, color = series),
    linewidth = 1.2
  ) +
  
  # 5-Year markers (exactly every 5 years)
  geom_vline(
    xintercept = seq(as.Date("1970-01-01"), as.Date("2025-01-01"), by = "5 years"),
    color = "gray50", linetype = "dotted", alpha = 0.5
  ) +
  
  # Formatting
  scale_x_date(
    limits = c(as.Date("1971-04-01"), as.Date("2024-12-31")),
    breaks = seq(as.Date("1970-01-01"), as.Date("2025-01-01"), by = "5 years"), # 5-year breaks
    expand = c(0, 0),
    date_labels = "%Y"
  ) +
  scale_y_continuous(
    labels = label_number(suffix = "%"),
    limits = c(0, max(combined_data$value, na.rm = TRUE) * 1.05)
  ) +
  scale_color_manual(
    values = c("#3574C2", "#E84A3B"), # Blue + red
    name = NULL
  ) +
  
  # Perfect title/subtitle spacing
  labs(
    title = "Federal Funds Rate vs. 30-Year Mortgage Rate (1971-Present)",
    subtitle = "Gray shading = NBER recessions | Dotted lines = 5-year intervals",
    caption = paste("Sources: FRED (MORTGAGE30US, FEDFUNDS) |", format(Sys.Date(), "%Y-%m-%d")),
    x = NULL,
    y = "Interest Rate (%)"
  ) +
  
 theme_economist() +
  theme(
    # Title settings (keep exactly the same)
    plot.title = element_text(
      size = 20, 
      face = "bold", 
      hjust = 0.5,
      margin = margin(b = 5)
    ),
    
    # Subtitle settings (keep exactly the same)
    plot.subtitle = element_text(
      size = 12,
      hjust = 0.5,
      margin = margin(b = 15)
    ),
    
    # ▼▼▼ MODIFY THESE TWO LINES ▼▼▼
    axis.text.x = element_text(
      angle = 45, 
      hjust = 1,
      margin = margin(t = -8, b = 5)  # CHANGED from default to t=-8 (nudges dates up)
    ),
    plot.caption = element_text(
      hjust = 1,
      size = 8,
      color = "gray30",
      margin = margin(t = 15, b = 5),  # CHANGED from b=0 to b=5 (nudges source down)
      vjust = 0                         # CHANGED from vjust=-1 to vjust=0 (more precise)
    ),
    # ▲▲▲ KEEP EVERYTHING BELOW THE SAME ▲▲▲
    legend.position = "top",
    plot.caption.position = "panel",
    panel.grid.major.x = element_blank()
  ) +
  coord_cartesian(clip = "off")


# 7. Save (same dimensions)
final_plot <- last_plot() + 
  theme(plot.caption = element_text(margin = margin(t = 25, b = -10)))

# Convert to grob and adjust
g <- ggplotGrob(final_plot)
g$layout$l[g$layout$name == "caption"] <- 2  # Ensure proper alignment
grid::grid.newpage()
grid::grid.draw(g)

# === THEN SAVE AS USUAL === #
ggsave(
  "fed_vs_mortgage_final.png",
  width = 16,
  height = 9,
  dpi = 300,
  bg = "white"
)