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
            { name: 'Total Revenue - 12 Week moving average', data: chartData.total_moving_avg },
            { name: '6-Week Revenue - 4 Week moving Average', data: chartData.six_week_moving_avg },
            { name: 'Total Revenue', data: chartData.total_revenue },
            { name: '6-Week Revenue', data: chartData.six_week_revenue }            
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
        colors: ['#000000', '#000000', '#00FF00', '#FF00FF'],
        grid: {
          borderColor: '#ffffff40'
        }
    };

    const chart = new ApexCharts(this.el, options);
    chart.render();

    this.handleEvent("updateChartData", (data) => {
        chart.updateSeries([
            { data: data.total_moving_avg },
            { data: data.six_week_moving_avg },
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
            animations: {
              enabled: false // Disable animations on update
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

ChartHooks.yearly_sales_Chart = {
  mounted() {
    let chartData = JSON.parse(this.el.dataset.yearlysalesChart);
    let totalSales = parseFloat(this.el.dataset.totalSales);
  
    // Prepend empty bars if the number of entries is less than 11
    while (chartData.series.length < 11) {
      chartData.series.unshift(0);  // Add empty bar (value 0)
      chartData.labels.unshift(''); // Add an empty label
    }
  
    const options = {
      series: [{
        data: chartData.series // Sales values
      }],
      chart: {
        type: 'bar',
        height: ['100%'],
        toolbar: {
          show: true
        },
        animations: {
          enabled: false // Disable animations on update
        }
      },
      plotOptions: {
        bar: {
          barHeight: '100%',
          distributed: true,
          horizontal: true,
          dataLabels: {
            position: 'bottom'
          },
        }
      },
      colors: [
        '#b71c1c', '#c62828', '#bf360c', '#d84315', '#ff6f00',
        '#ff8f00', '#ffb300', '#33691e', '#1b5e20', '#004d40', '#00695c'
      ],
      dataLabels: {
        enabled: true,
        textAnchor: 'start',
        style: {
          colors: ['#ffffff'],
          fontSize: '20px'
        },
        formatter: function (val, opt) {
          const percentage = ((val / totalSales) * 100).toFixed(2);
          
          return `${chartData.labels[opt.dataPointIndex]}: ${val.toLocaleString('en-US', {
            style: 'currency',
            currency: 'USD'
          })} (${percentage}%)`;
        },
        offsetX: 0,
        dropShadow: {
          enabled: false
        }
      },
      stroke: {
        width: 1,
        colors: ['#fff']
      },
      xaxis: {
        categories: chartData.labels,
        labels: {
          style: {
            colors: '#ffffff',
            fontSize: '16px'
          }
        }
      },
      yaxis: {
        labels: {
          show: false
        }
      },
      title: {
        text: 'Yearly Sales by Customer',
        align: 'center',
        floating: true,
        style: {
          color: '#ffffff',
          fontSize: '20px'
        }
      },
      legend: {
        show: false,
        labels: {
          colors: '#ffffff',
          fontSize: '18px'
        }
      },
      tooltip: {
        theme: 'dark',
        x: {
          show: false
        },
        y: {
          title: {
            formatter: function () {
              return '';
            }
          }
        }
      }
    };
  
    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },
  
  updated() {
    let updatedChartData = JSON.parse(this.el.dataset.yearlysalesChart);
    let updatedTotalSales = parseFloat(this.el.dataset.totalSales);
  
    // Prepend empty bars if the number of entries is less than 11
    while (updatedChartData.series.length < 11) {
      updatedChartData.series.unshift(0);
      updatedChartData.labels.unshift('');
    }
  
    this.chart.updateOptions({
      series: [{
        data: updatedChartData.series
      }],
      xaxis: {
        categories: updatedChartData.labels
      },
      dataLabels: {
        formatter: function (val, opt) {
          const percentage = ((val / updatedTotalSales) * 100).toFixed(2);
          
          return `${updatedChartData.labels[opt.dataPointIndex]}: ${val.toLocaleString('en-US', {
            style: 'currency',
            currency: 'USD'
          })} (${percentage}%)`;
        }
      }
    });
  }
};
  

export default ChartHooks;