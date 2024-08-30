import ApexCharts from 'apexcharts';

let ChartHooks = {};

ChartHooks.Revenue_Chart = {
  mounted() {
    const chartData = JSON.parse(this.el.dataset.revenueChart);
    
    const options = {
        chart: {
            type: 'line',
            height: '100%',
            zoom: {
                enabled: true,
                type: 'xy'
            },
            toolbar: {
                show: true,
                tools: {
                    download: true,
                    selection: true,
                    zoom: true,
                    zoomin: true,
                    zoomout: true,
                    pan: true,
                    reset: true
                },
                autoSelected: 'zoom'
            },
            foreColor: '#ffffff' // This sets the base text color for the chart
        },
        series: [
            {
                name: 'Total Revenue',
                data: chartData.total_revenue
            },
            {
                name: '6-Week Revenue',
                data: chartData.six_week_revenue
            }
        ],
        xaxis: {
          type: 'datetime',
          labels: {
              style: {
                  colors: '#ffffff',
                  fontSize: '14px' // Increase x-axis label font size
              }
          }
        },
        yaxis: {
            labels: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                },
                style: {
                  colors: '#ffffff',
                  fontSize: '14px' // Increase y-axis label font size
              }
            }            
        },
        tooltip: {
            x: {
                format: 'dd MMM yyyy'
            },
            y: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            }
        },
        legend: {
            position: 'top'
        },
        colors: ['#008FFB', '#00E396']
    };

    const chart = new ApexCharts(this.el, options);
    chart.render();

    this.handleEvent("updateChartData", (data) => {
        chart.updateSeries([
            { data: data.total_revenue },
            { data: data.six_week_revenue }
        ]);
    });
}
}

ChartHooks.monthly_sales_chart = {
  mounted() {
    const chartData = JSON.parse(this.el.dataset.salesChart);
    const currentYear = new Date().getFullYear().toString();
    const previousYear = (new Date().getFullYear() - 1).toString();
    const yearBeforePrevious = (new Date().getFullYear() - 2).toString();

    const options = {
        chart: {
            type: 'line',
            height: '100%',
            zoom: {
                enabled: true,
                type: 'y'
            },
            foreColor: '#ffffff',
            background: 'transparent'
        },
        series: chartData.series,
        xaxis: {
            type: 'category',
            categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
            labels: {
                style: {
                    colors: '#ffffff',
                    fontSize: '16px'
                }
            },
            title: {
                text: 'Month',
                style: {
                    color: '#ffffff',
                    fontSize: '16px'
                }
            },
            tickAmount: 12  // Ensure 12 ticks for each month
        },
        yaxis: {
            title: {
                text: 'Revenue',
                style: {
                    color: '#ffffff',
                    fontSize: '18px'
                }
            },
            labels: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                },
                style: {
                    colors: '#ffffff',
                    fontSize: '18px'
                }
            }
        },
        tooltip: {
            enabled: true,
            shared: false,
            intersect: false,
            theme: 'dark',
            x: {
                
            },
            y: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            },
            style: {
                fontSize: '18px'
            },
            custom: function({series, seriesIndex, dataPointIndex, w}) {
                let tooltipContent = '<div></div>';
        
                let seriesData = [];
                series.forEach((s, i) => {
                    let value = s[dataPointIndex];
                    if (value !== undefined && value !== null) {
                        seriesData.push({
                            color: w.globals.colors[i],
                            seriesName: w.globals.seriesNames[i],
                            value: w.globals.yLabelFormatters[0](value)
                        });
                    }
                });
        
                seriesData.reverse();
        
                seriesData.forEach((data, index) => {
                    tooltipContent += `<div class="apexcharts-tooltip-series-group" style="order: ${index+1}; display: flex;">
                        <span class="apexcharts-tooltip-marker" style="background-color: ${data.color};"></span>
                        <div class="apexcharts-tooltip-text" style="font-family: Helvetica, Arial, sans-serif; font-size: 18px;">
                            <div class="apexcharts-tooltip-y-group">
                                <span class="apexcharts-tooltip-text-y-label">${data.seriesName}: </span>
                                <span class="apexcharts-tooltip-text-y-value">${data.value}</span>
                            </div>
                        </div>
                    </div>`;
                });
        
                return tooltipContent;
            }
        },
        legend: {
            position: 'top',
            fontSize: '14px',
            labels: {
                colors: '#ffffff'
            }
        },
        stroke: {
          width: chartData.series.map(s => {
              if (s.name === currentYear) {
                  return 10;  // Thickest line for the current year
              } else if (s.name === previousYear) {
                  return 6;  // Slightly thinner line for the previous year
              } else if (s.name === yearBeforePrevious) {
                  return 4;  // Even thinner line for the year before previous
              } else {
                  return 2;  // Default line width for all other years
              }
          }),
          curve: 'straight'  // This removes line rounding
        },      
        colors: chartData.series.map(s => {
          if (s.name === currentYear) {
              return '#00FF00'; // Bright Green for current year
          } else if (s.name === previousYear) {
              return '#FF00FF';  // Bright Magenta for year before previous
          } else if (s.name === yearBeforePrevious) {
              return '#FFA500';  // Bright Orange for previous year
          } else {
              return '#A9A9A9';  // Muted Light Gray for all other years
          }
      }),
        grid: {
            borderColor: '#ffffff40'
        },
        dataLabels: {
            enabled: false
        }
    };

    const chart = new ApexCharts(this.el, options);
    chart.render();

    this.handleEvent("updateChartData", (data) => {
        chart.updateSeries(data.series);
    });
  }
}

export default ChartHooks;