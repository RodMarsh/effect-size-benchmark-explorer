# Interactive Effect-Size Benchmark Explorer
# ---------------------------------------------------------------------------
# Shiny app comparing Cohen's generic effect-size benchmarks against
# ecohydrology thresholds. Users can adjust d and distribution family
# to see how density overlap and benchmark classification change.
#
# Distributional benchmarks (Cohen, Cliff's delta, Richter RVA, Nathan)
# are shown on the d axis. Percentage-based thresholds (Richter presumptive,
# MDB 80%) are shown on a separate static panel with their own % change axis,
# since they cannot be mapped to d without site-specific CV.
#
# Run with: shiny::runApp("R/shiny_effect_size_benchmarks")
# ---------------------------------------------------------------------------
library(munsell) 
library(tibble)
library(shiny)
library(bslib)
library(ggplot2)

# ---- Helper functions ------------------------------------------------------

cliff_from_d <- function(d) 2 * pnorm(d / sqrt(2)) - 1
vda_from_d   <- function(d) pnorm(d / sqrt(2))

# Nathan non-overlapping area thresholds -> d
d_nathan_025 <- -2 * qnorm((1 - 0.25) / 2)
d_nathan_050 <- -2 * qnorm((1 - 0.50) / 2)
d_nathan_075 <- -2 * qnorm((1 - 0.75) / 2)

# Cliff's delta thresholds -> d
# Vargha & Delaney 2000 thresholds
d_cliff_vd_sm <- sqrt(2) * qnorm((1 + 0.11) / 2)
d_cliff_vd_md <- sqrt(2) * qnorm((1 + 0.28) / 2)
d_cliff_vd_lg <- sqrt(2) * qnorm((1 + 0.43) / 2)

# Romano et al. 2006 thresholds
d_cliff_ro_sm <- sqrt(2) * qnorm((1 + 0.147) / 2)
d_cliff_ro_md <- sqrt(2) * qnorm((1 + 0.33) / 2)
d_cliff_ro_lg <- sqrt(2) * qnorm((1 + 0.474) / 2)

# Colours
col_baseline <- "#2166AC"
col_scenario <- "#B2182B"
col_cohen    <- "#636363"
col_cliff    <- "#e6550d"
col_indicator <- "#d32f2f"

# Helper: make rect df (avoids lazy aes evaluation issues)
make_rect <- function(xmin, xmax, ymin, ymax) {
  data.frame(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
}

# Helper: make segment df
make_seg <- function(x, y, yend) {
  data.frame(x = x, xend = x, y = y, yend = yend)
}

# ---- UI --------------------------------------------------------------------

ui <- bslib::page_sidebar(
  title = "Effect-size benchmark explorer - Cohen's conventional values compared with ecohydrology proposals",
  theme = bslib::bs_theme(bootswatch = "flatly", base_font = "system-ui"),

  sidebar = bslib::sidebar(
    width = 280, open = "desktop",
    shiny::sliderInput("d_val", "Effect size (d)",
                       min = 0, max = 3, value = 0.1, step = 0.05),
    shiny::selectInput("dist_family", "Distribution family",
                       choices = c("Normal", "Log-normal", "Gamma"),
                       selected = "Normal"),
    shiny::radioButtons("cliff_thresholds", "Cliff's \u03b4 thresholds",
                        choices = c("Vargha & Delaney (2000)" = "vd",
                                    "Romano et al. (2006)" = "romano"),
                        selected = "vd"),
    shiny::checkboxGroupInput("benchmarks", "Show benchmarks (d axis)",
                              choices = c("Cohen's d" = "cohen",
                                          "Cliff's \u03b4" = "cliff",
                                          "Richter RVA" = "rva",
                                          "Nathan stress score" = "nathan"),
                              selected = c("cohen", "cliff", "rva", "nathan")),
    shiny::checkboxGroupInput("pct_benchmarks", "Show benchmarks (% axis)",
                              choices = c("Richter presumptive" = "richter_pres",
                                          "MDB 80% (largely unmod.)" = "mdb"),
                              selected = c("richter_pres", "mdb")),
    hr(),
    shiny::htmlOutput("metrics_text"),
    hr(),
    shiny::tags$p(
      style = "font-size: 11px; color: #6c757d; line-height: 1.4;",
      shiny::HTML(paste0(
        "<strong>Note on normality</strong><br>",
        "Density curves and benchmark\u2013d mappings assume normality for illustration. ",
        "Cliff\u2019s \u03b4 (the primary AROWS metric) is fully nonparametric ",
        "and does not assume any distributional form. ",
        "Switch to log-normal or gamma above to see how non-normality ",
        "affects overlap and metric values."
      ))
    ),
    shiny::tags$p(
      style = "font-size: 11px; color: #6c757d; line-height: 1.4;",
      shiny::HTML(
        "<strong>Note on %-change panel</strong><br>Richter presumptive and MDB 80% are ratio thresholds that cannot be mapped to d without site-specific CV. They are shown on a separate axis for reference. Richter originally proposed change from mean daily flow (Richter, 2012). MDB assessments for the Basin Plan considered a ‘largely unmodified flow regime’ to be 'where the modelled end-of-system flow under pre-Basin Plan water sharing arrangements was greater than 80% of without-development flows.' (Swirepik, 2016)"
      )
    )
  ),

  bslib::layout_columns(
    col_widths = 12,
    bslib::card(
      bslib::card_header("Distributional overlap"),
      shiny::plotOutput("density_plot", height = "280px")
    ),
    bslib::card(
      bslib::card_header("Distributional benchmarks (d axis)"),
      shiny::plotOutput("ruler_plot", height = "400px")
    ),
    bslib::card(
      bslib::card_header("Percentage-based thresholds (% change from baseline)"),
      shiny::plotOutput("pct_plot", height = "200px")
    )
  )
)

# ---- Server ----------------------------------------------------------------

server <- function(input, output, session) {

  base_size <- 12

  theme_bench <- ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      legend.position    = "none",
      panel.grid.minor   = ggplot2::element_blank(),
      plot.title         = ggplot2::element_text(face = "bold", size = base_size + 1),
      plot.subtitle      = ggplot2::element_text(size = base_size - 1, colour = "grey40")
    )

  # Reactive: generate density data
  density_data <- shiny::reactive({
    d <- input$d_val
    family <- input$dist_family

    if (family == "Normal") {
      x <- seq(-4, 6, length.out = 500)
      data.frame(
        x = rep(x, 2),
        density = c(dnorm(x, 0, 1), dnorm(x, d, 1)),
        group = rep(c("Baseline", "Scenario"), each = length(x))
      )
    } else if (family == "Log-normal") {
      x <- seq(0.001, 15, length.out = 500)
      data.frame(
        x = rep(x, 2),
        density = c(dlnorm(x, 0, 1), dlnorm(x, d, 1)),
        group = rep(c("Baseline", "Scenario"), each = length(x))
      )
    } else {
      shape <- 4
      rate <- 1
      sd_gamma <- sqrt(shape) / rate
      x <- seq(0.001, 20, length.out = 500)
      shift <- d * sd_gamma
      data.frame(
        x = rep(x, 2),
        density = c(dgamma(x, shape, rate),
                    dgamma(x - shift, shape, rate) * (x > shift)),
        group = rep(c("Baseline", "Scenario"), each = length(x))
      )
    }
  })

  # Reactive: compute metrics
  metrics <- shiny::reactive({
    d <- input$d_val
    family <- input$dist_family

    if (family == "Normal") {
      vda <- round(vda_from_d(d), 3)
      cliff <- round(cliff_from_d(d), 3)
    } else {
      set.seed(42)
      n <- 10000
      if (family == "Log-normal") {
        baseline <- rlnorm(n, 0, 1)
        scenario <- rlnorm(n, d, 1)
      } else {
        shape <- 4
        rate <- 1
        sd_gamma <- sqrt(shape) / rate
        baseline <- rgamma(n, shape, rate)
        scenario <- rgamma(n, shape, rate) + d * sd_gamma
      }
      vda <- round(mean(scenario > baseline) + 0.5 * mean(scenario == baseline), 3)
      cliff <- round(2 * vda - 1, 3)
    }

    non_overlap <- round(1 - 2 * pnorm(-d / 2), 3)

    nathan_cat <- if (non_overlap < 0.25) "No concern"
    else if (non_overlap < 0.50) "Some concern"
    else if (non_overlap < 0.75) "Rel. greater concern"
    else "High concern"

    cohen_cat <- if (d < 0.2) "Negligible"
    else if (d < 0.5) "Small"
    else if (d < 0.8) "Medium"
    else "Large"

    cliff_abs <- abs(cliff)
    if (input$cliff_thresholds == "vd") {
      cliff_cat <- if (cliff_abs <= 0.11) "Negligible"
      else if (cliff_abs <= 0.28) "Small"
      else if (cliff_abs <= 0.43) "Medium"
      else "Large"
    } else {
      cliff_cat <- if (cliff_abs <= 0.147) "Negligible"
      else if (cliff_abs <= 0.33) "Small"
      else if (cliff_abs <= 0.474) "Medium"
      else "Large"
    }

    list(vda = vda, cliff = cliff,
         non_overlap = non_overlap, nathan_cat = nathan_cat,
         cohen_cat = cohen_cat, cliff_cat = cliff_cat)
  })

  # Density plot
  output$density_plot <- shiny::renderPlot({
    d <- input$d_val
    df <- density_data()
    m <- metrics()

    subtitle <- sprintf("d = %.2f  |  VDA = %.3f  |  \u03b4 = %.3f  |  Cohen: %s",
                        d, m$vda, m$cliff, m$cohen_cat)

    ggplot2::ggplot(df, ggplot2::aes(x = x, y = density, fill = group)) +
      ggplot2::geom_area(alpha = 0.4, position = "identity", colour = NA) +
      ggplot2::geom_line(ggplot2::aes(colour = group), linewidth = 0.6) +
      ggplot2::scale_fill_manual(values = c(Baseline = col_baseline,
                                            Scenario = col_scenario)) +
      ggplot2::scale_colour_manual(values = c(Baseline = col_baseline,
                                              Scenario = col_scenario)) +
      ggplot2::labs(
        title = paste0(input$dist_family, " distributions"),
        subtitle = subtitle,
        x = NULL, y = NULL
      ) +
      theme_bench +
      ggplot2::theme(
        axis.text.y  = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank()
      )
  }, res = 96)

  # Ruler plot (d axis — distributional benchmarks only)
  output$ruler_plot <- shiny::renderPlot({
    d <- input$d_val
    show <- input$benchmarks

    x_max <- 2.6

    # Build row positions dynamically based on visible benchmarks
    row_order <- c("nathan", "rva", "cliff", "cohen")
    visible <- row_order[row_order %in% show]
    n_rows <- length(visible)

    if (n_rows == 0) {
      return(ggplot2::ggplot() +
               ggplot2::annotate("text", x = 0, y = 0.5,
                                 label = "Select at least one benchmark",
                                 size = 5, colour = "grey50") +
               ggplot2::theme_void())
    }

    # Assign y positions (more spacing for readability)
    row_y <- setNames(seq(0.6, by = 0.8, length.out = n_rows), visible)

    # Build y-axis label lookup (used by scale_y_continuous)
    label_lookup <- c(
      cohen  = "Cohen's d",
      cliff  = if (input$cliff_thresholds == "vd")
                 "Cliff's \u03b4 (V&D 2000)" else "Cliff's \u03b4 (Romano 2006)",
      rva    = "Richter RVA",
      nathan = "Nathan stress score"
    )
    y_breaks <- unname(row_y) + 0.25
    y_labels <- unname(label_lookup[visible])

    # Scale annotation text to plot width (reference = 800 px)
    plot_w <- session$clientData$output_ruler_plot_width %||% 800
    txt_scale <- min(1, plot_w / 800)

    # Collect all rect data and annotation data
    rect_list <- list()
    ann_list  <- list()

    add_rect <- function(xmin, xmax, ymin, ymax, fill) {
      rect_list[[length(rect_list) + 1]] <<- data.frame(
        xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
        fill = fill, stringsAsFactors = FALSE
      )
    }

    add_ann <- function(x, y, label, size = 3.0, colour = "black",
                        fontface = "plain", hjust = 0.5, lineheight = 1.0,
                        parse_expr = FALSE) {
      ann_list[[length(ann_list) + 1]] <<- list(
        x = x, y = y, label = label, size = size * txt_scale, colour = colour,
        fontface = fontface, hjust = hjust, lineheight = lineheight,
        parse_expr = parse_expr
      )
    }

    # --- Cohen ---
    if ("cohen" %in% visible) {
      ylo <- row_y["cohen"]
      yhi <- ylo + 0.5
      ymid <- ylo + 0.25
      add_rect(-0.8, -0.5, ylo, yhi, "#636363")
      add_rect(-0.5, -0.2, ylo, yhi, "#969696")
      add_rect(-0.2,  0.0, ylo, yhi, "#d9d9d9")
      add_rect( 0.0,  0.2, ylo, yhi, "#d9d9d9")
      add_rect( 0.2,  0.5, ylo, yhi, "#969696")
      add_rect( 0.5,  0.8, ylo, yhi, "#636363")
      add_ann(0, ymid, "negl.", size = 2.5, colour = "black")
      add_ann(0.35, ymid, "small", size = 2.5, colour = "white", fontface = "bold")
      add_ann(-0.35, ymid, "small", size = 2.5, colour = "white", fontface = "bold")
      add_ann(0.65, ymid, "med.", size = 2.5, colour = "white", fontface = "bold")
      add_ann(-0.65, ymid, "med.", size = 2.5, colour = "white", fontface = "bold")
      add_ann(1.05, ymid, "large \u2192", size = 2.5, colour = col_cohen)
      add_ann(-1.05, ymid, "\u2190 large", size = 2.5, colour = col_cohen)
      # row label now rendered via scale_y_continuous
    }

    # --- Cliff's delta ---
    if ("cliff" %in% visible) {
      ylo <- row_y["cliff"]
      yhi <- ylo + 0.5
      ymid <- ylo + 0.25
      if (input$cliff_thresholds == "vd") {
        csm <- d_cliff_vd_sm; cmd <- d_cliff_vd_md; clg <- d_cliff_vd_lg
        t_sm <- 0.11; t_md <- 0.28; t_lg <- 0.43
        cliff_label <- "Cliff\u2019s \u03b4\n(V&D 2000)"
      } else {
        csm <- d_cliff_ro_sm; cmd <- d_cliff_ro_md; clg <- d_cliff_ro_lg
        t_sm <- 0.147; t_md <- 0.33; t_lg <- 0.474
        cliff_label <- "Cliff\u2019s \u03b4\n(Romano 2006)"
      }
      add_rect(-clg, -cmd, ylo, yhi, "#fdae6b")
      add_rect(-cmd, -csm, ylo, yhi, "#fee6ce")
      add_rect(-csm, 0, ylo, yhi, "#fff5eb")
      add_rect(0, csm, ylo, yhi, "#fff5eb")
      add_rect(csm, cmd, ylo, yhi, "#fee6ce")
      add_rect(cmd, clg, ylo, yhi, "#fdae6b")
      add_ann(0, ymid + 0.06, "negl.", size = 2.5, colour = "#8c510a")
      add_ann(0, ymid - 0.08, sprintf("\u03b4 \u2264 %.3g", t_sm), size = 1.8,
              colour = "#8c510a")
      add_ann((csm + cmd) / 2, ymid + 0.06, "small", size = 2.5,
              colour = "#8c510a")
      add_ann((csm + cmd) / 2, ymid - 0.08,
              sprintf("%.3g\u2013%.2g", t_sm, t_md), size = 1.8,
              colour = "#8c510a")
      add_ann(-(csm + cmd) / 2, ymid + 0.06, "small", size = 2.5,
              colour = "#8c510a")
      add_ann(-(csm + cmd) / 2, ymid - 0.08,
              sprintf("%.3g\u2013%.2g", t_sm, t_md), size = 1.8,
              colour = "#8c510a")
      add_ann((cmd + clg) / 2, ymid + 0.06, "med.", size = 2.5,
              colour = "#8c510a")
      add_ann((cmd + clg) / 2, ymid - 0.08,
              sprintf("%.2g\u2013%.3g", t_md, t_lg), size = 1.8,
              colour = "#8c510a")
      add_ann(-(cmd + clg) / 2, ymid + 0.06, "med.", size = 2.5,
              colour = "#8c510a")
      add_ann(-(cmd + clg) / 2, ymid - 0.08,
              sprintf("%.2g\u2013%.3g", t_md, t_lg), size = 1.8,
              colour = "#8c510a")
      add_ann(1.05, ymid, "large \u2192", size = 2.5, colour = col_cliff)
      add_ann(-1.05, ymid, "\u2190 large", size = 2.5, colour = col_cliff)
      # row label now rendered via scale_y_continuous
    }

    # --- Richter RVA ---
    if ("rva" %in% visible) {
      ylo <- row_y["rva"]
      yhi <- ylo + 0.5
      ymid <- ylo + 0.25
      add_rect(-1.0, 1.0, ylo, yhi, "#b2dfdb")
      add_ann(0, ymid, "within \u00b11 SD natural envelope",
              size = 3.2, colour = "#00695c", fontface = "bold")
      # row label now rendered via scale_y_continuous
    }

    # --- Nathan stress score ---
    if ("nathan" %in% visible) {
      ylo <- row_y["nathan"]
      yhi <- ylo + 0.5
      ymid <- ylo + 0.25
      # Positive side
      add_rect(0, d_nathan_025, ylo, yhi, "#e8d5b7")
      add_rect(d_nathan_025, d_nathan_050, ylo, yhi, "#d4a76a")
      add_rect(d_nathan_050, d_nathan_075, ylo, yhi, "#b8763e")
      add_rect(d_nathan_075, x_max, ylo, yhi, "#8b4513")
      # Negative side
      add_rect(-d_nathan_025, 0, ylo, yhi, "#e8d5b7")
      add_rect(-d_nathan_050, -d_nathan_025, ylo, yhi, "#d4a76a")
      add_rect(-d_nathan_075, -d_nathan_050, ylo, yhi, "#b8763e")
      add_rect(-x_max, -d_nathan_075, ylo, yhi, "#8b4513")
      add_ann(0, ymid, "No\nconcern", size = 2.5, colour = "#5d4037",
              lineheight = 0.9)
      add_ann((d_nathan_025 + d_nathan_050) / 2, ymid, "Some\nconcern",
              size = 2.5, colour = "white", lineheight = 0.9)
      add_ann(-(d_nathan_025 + d_nathan_050) / 2, ymid, "Some\nconcern",
              size = 2.5, colour = "white", lineheight = 0.9)
      add_ann((d_nathan_050 + d_nathan_075) / 2, ymid, "Rel. greater\nconcern",
              size = 2.2, colour = "white", lineheight = 0.9)
      add_ann(-(d_nathan_050 + d_nathan_075) / 2, ymid, "Rel. greater\nconcern",
              size = 2.2, colour = "white", lineheight = 0.9)
      add_ann((d_nathan_075 + x_max) / 2, ymid, "High", size = 2.5,
              colour = "white", fontface = "bold")
      add_ann(-(d_nathan_075 + x_max) / 2, ymid, "High", size = 2.5,
              colour = "white", fontface = "bold")
      # row label now rendered via scale_y_continuous
    }

    # Build the plot from collected data
    rect_df <- do.call(rbind, rect_list)
    p <- ggplot2::ggplot() +
      ggplot2::geom_rect(
        data = rect_df,
        ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
        fill = rect_df$fill, colour = "white", linewidth = 0.4
      )

    # Add annotations (handle parse separately)
    for (a in ann_list) {
      if (isTRUE(a$parse_expr)) {
        p <- p + ggplot2::annotate("text", x = a$x, y = a$y, label = a$label,
                                   parse = TRUE, size = a$size, colour = a$colour,
                                   hjust = a$hjust, lineheight = a$lineheight)
      } else {
        p <- p + ggplot2::annotate("text", x = a$x, y = a$y, label = a$label,
                                   size = a$size, colour = a$colour,
                                   fontface = a$fontface, hjust = a$hjust,
                                   lineheight = a$lineheight)
      }
    }

    # Y limits
    y_min <- min(row_y) - 0.2
    y_max <- max(row_y) + 0.8

    # Indicator line + axes
    p <- p +
      ggplot2::geom_vline(xintercept = 0, colour = "grey30", linewidth = 0.3) +
      ggplot2::geom_vline(xintercept = d, colour = col_indicator,
                          linewidth = 1, linetype = "solid", alpha = 0.7) +
      ggplot2::geom_vline(xintercept = -d, colour = col_indicator,
                          linewidth = 1, linetype = "dashed", alpha = 0.4) +
      ggplot2::annotate("text", x = d, y = y_max + 0.05,
                        label = sprintf("d = %.2f", d),
                        size = 3.5, colour = col_indicator, fontface = "bold",
                        vjust = 0) +
      ggplot2::coord_cartesian(
        xlim = c(-x_max - 0.2, x_max + 0.2),
        ylim = c(y_min, y_max + 0.15)
      ) +
      ggplot2::scale_x_continuous(
        name = "Standardised effect size  d",
        breaks = seq(-2.5, 2.5, 0.5)
      ) +
      ggplot2::scale_y_continuous(
        breaks = y_breaks,
        labels = y_labels
      ) +
      theme_bench +
      ggplot2::theme(
        axis.ticks.y       = ggplot2::element_blank(),
        axis.title.y       = ggplot2::element_blank(),
        axis.text.y        = ggplot2::element_text(
          face = "bold", size = 10, colour = "grey30"
        ),
        panel.grid.major.y = ggplot2::element_blank()
      )

    p
  }, res = 96)

  # Percentage-change panel (static — no reactivity needed)
  output$pct_plot <- shiny::renderPlot({
    show_pct <- input$pct_benchmarks

    pct_max <- 50
    pct_margin <- 8

    # Build row positions dynamically
    row_order <- c("mdb", "richter_pres")
    visible <- row_order[row_order %in% show_pct]
    n_rows <- length(visible)

    if (n_rows == 0) {
      return(ggplot2::ggplot() +
               ggplot2::annotate("text", x = 0, y = 0.5,
                                 label = "Select at least one benchmark",
                                 size = 5, colour = "grey50") +
               ggplot2::theme_void())
    }

    row_y <- setNames(seq(0.6, by = 0.8, length.out = n_rows), visible)

    # Build y-axis label lookup
    pct_label_lookup <- c(
      richter_pres = "Richter presumptive",
      mdb          = "MDB 80%"
    )
    pct_y_breaks <- unname(row_y) + 0.25
    pct_y_labels <- unname(pct_label_lookup[visible])

    # Scale annotation text to plot width (reference = 800 px)
    pct_w <- session$clientData$output_pct_plot_width %||% 800
    pct_txt_scale <- min(1, pct_w / 800)

    rect_list <- list()
    ann_list  <- list()

    add_rect <- function(xmin, xmax, ymin, ymax, fill) {
      rect_list[[length(rect_list) + 1]] <<- data.frame(
        xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
        fill = fill, stringsAsFactors = FALSE
      )
    }

    add_ann <- function(x, y, label, size = 3.0, colour = "black",
                        fontface = "plain", hjust = 0.5, lineheight = 1.0) {
      ann_list[[length(ann_list) + 1]] <<- list(
        x = x, y = y, label = label, size = size * pct_txt_scale, colour = colour,
        fontface = fontface, hjust = hjust, lineheight = lineheight
      )
    }

    # --- Richter presumptive (bidirectional) ---
    if ("richter_pres" %in% visible) {
      ylo <- row_y["richter_pres"]
      yhi <- ylo + 0.5
      ymid <- ylo + 0.25
      add_rect(-pct_max, -20, ylo, yhi, "#283593")
      add_rect(20, pct_max, ylo, yhi, "#283593")
      add_rect(-20, -10, ylo, yhi, "#c5cae9")
      add_rect(10, 20, ylo, yhi, "#c5cae9")
      add_rect(-10, 10, ylo, yhi, "#e8eaf6")
      add_ann(0, ymid, "High\n(<10%)", size = 2.8, colour = "#283593",
              lineheight = 0.85)
      add_ann(15, ymid, "Mod.\n(10\u201320%)", size = 2.5,
              colour = "#283593", lineheight = 0.85)
      add_ann(-15, ymid, "Mod.\n(10\u201320%)", size = 2.5,
              colour = "#283593", lineheight = 0.85)
      add_ann(35, ymid, "exceeds", size = 2.8, colour = "white",
              fontface = "bold")
      add_ann(-35, ymid, "exceeds", size = 2.8, colour = "white",
              fontface = "bold")
      # row label now rendered via scale_y_continuous
    }

    # --- MDB 80% (unidirectional) ---
    if ("mdb" %in% visible) {
      ylo <- row_y["mdb"]
      yhi <- ylo + 0.5
      ymid <- ylo + 0.25
      add_rect(-pct_max, -20, ylo, yhi, "#ffcdd2")
      add_rect(-20, 0, ylo, yhi, "#c8e6c9")
      add_rect(0, pct_max, ylo, yhi, "#f5f5f5")
      add_ann(-10, ymid, "largely\nunmodified\n(>80%)", size = 2.5,
              colour = "#2e7d32", lineheight = 0.85)
      add_ann(-35, ymid, "\u2190 modified\n(<80%)", size = 2.5,
              colour = "#c62828", lineheight = 0.85)
      add_ann(25, ymid, "increases (N/A)", size = 2.2,
              colour = "#9e9e9e", fontface = "italic")
      # row label now rendered via scale_y_continuous
    }

    # Build plot
    rect_df <- do.call(rbind, rect_list)
    p <- ggplot2::ggplot() +
      ggplot2::geom_rect(
        data = rect_df,
        ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
        fill = rect_df$fill, colour = "white", linewidth = 0.4
      )

    for (a in ann_list) {
      p <- p + ggplot2::annotate("text", x = a$x, y = a$y, label = a$label,
                                 size = a$size, colour = a$colour,
                                 fontface = a$fontface, hjust = a$hjust,
                                 lineheight = a$lineheight)
    }

    y_min <- min(row_y) - 0.2
    y_max <- max(row_y) + 0.8

    p <- p +
      ggplot2::geom_vline(xintercept = 0, colour = "grey30", linewidth = 0.3) +
      ggplot2::coord_cartesian(
        xlim = c(-pct_max - 2, pct_max + 2),
        ylim = c(y_min, y_max)
      ) +
      ggplot2::scale_x_continuous(
        name = "% change",
        breaks = seq(-50, 50, 10)
      ) +
      ggplot2::scale_y_continuous(
        breaks = pct_y_breaks,
        labels = pct_y_labels
      ) +
      ggplot2::labs(
        subtitle = "Mean-ratio thresholds (cannot be mapped to d without site-specific CV)"
      ) +
      theme_bench +
      ggplot2::theme(
        axis.ticks.y       = ggplot2::element_blank(),
        axis.title.y       = ggplot2::element_blank(),
        axis.text.y        = ggplot2::element_text(
          face = "bold", size = 10, colour = "grey30"
        ),
        panel.grid.major.y = ggplot2::element_blank()
      )

    p
  }, res = 96)

  # Metrics text
  output$metrics_text <- shiny::renderUI({
    m <- metrics()
    d <- input$d_val
    non_ov <- m$non_overlap

    shiny::HTML(paste0(
      "<div style='font-size: 13px; line-height: 1.6;'>",
      "<strong>Computed metrics</strong><br>",
      "d = ", sprintf("%.2f", d), "<br>",
      "VDA = ", sprintf("%.3f", m$vda), "<br>",
      "\u03b4 (Cliff) = ", sprintf("%.3f", m$cliff), "<br>",
      "Non-overlap = ", sprintf("%.3f", non_ov), "<br>",
      "<hr style='margin: 6px 0;'>",
      "<strong>Classifications</strong><br>",
      "Cohen: ", m$cohen_cat, "<br>",
      "Cliff: ", m$cliff_cat, "<br>",
      "Nathan: ", m$nathan_cat,
      "</div>"
    ))
  })
}

shiny::shinyApp(ui, server)
