/**
 * Reports Dashboard for APU Medical Center
 * This file contains functions to retrieve and display real data from the database
 */

// Initialize charts and data containers
let revenueChart, appointmentChart, staffPerformanceChart, demographicsChart;
let dashboardData = {};

// Main initialization function
document.addEventListener('DOMContentLoaded', function() {
    console.log('Reports dashboard initializing with real data...');
    
    // Load initial data
    loadDashboardData();
    
    // Set up event listeners for chart controls
    setupChartControls();
});

// Load dashboard data from server
function loadDashboardData() {
    showLoadingIndicator();
    
    // Fetch dashboard data from servlet
    fetch(`${contextPath}/ReportServlet?action=dashboard_data`)
        .then(response => {
            if (!response.ok) {
                throw new Error(`Server returned ${response.status} ${response.statusText}`);
            }
            return response.json();
        })
        .then(data => {
            console.log('Dashboard data loaded successfully:', data);
            
            // Store data for reference
            dashboardData = data;
            
            // Update UI components
            updateKPIs(data);
            updateTables(data);
            
            // Initialize charts after data is loaded
            initializeCharts();
            
            hideLoadingIndicator();
        })
        .catch(error => {
            console.error('Error loading dashboard data:', error);
            showErrorMessage('Failed to load dashboard data. Please try refreshing the page.');
            hideLoadingIndicator();
        });
}

// Update Key Performance Indicators
function updateKPIs(data) {
    document.getElementById('totalRevenue').textContent = 'RM ' + (data.totalRevenue || '0.00');
    document.getElementById('totalAppointments').textContent = data.totalAppointments || '0';
    document.getElementById('totalStaff').textContent = data.totalStaff || '0';
    document.getElementById('avgRating').textContent = (data.avgRating || '0.0') + '/10';
}

// Update tables with real data
function updateTables(data) {
    // Update top doctors table
    if (data.topDoctors && data.topDoctors.length > 0) {
        let topDoctorsHtml = '';
        data.topDoctors.forEach((doctor, index) => {
            topDoctorsHtml += `
                <tr>
                    <td>${index + 1}</td>
                    <td>${doctor.name}</td>
                    <td>${doctor.specialization}</td>
                    <td><span class="rating-badge">${doctor.rating}/10</span></td>
                    <td>${doctor.appointments}</td>
                </tr>
            `;
        });
        document.getElementById('topDoctorsTable').innerHTML = topDoctorsHtml;
    }

    // Update most booked doctors table
    if (data.mostBooked && data.mostBooked.length > 0) {
        let mostBookedHtml = '';
        data.mostBooked.forEach((doctor, index) => {
            mostBookedHtml += `
                <tr>
                    <td>${index + 1}</td>
                    <td>${doctor.name}</td>
                    <td>${doctor.specialization}</td>
                    <td>${doctor.bookings}</td>
                    <td>RM ${doctor.revenue}</td>
                </tr>
            `;
        });
        document.getElementById('mostBookedTable').innerHTML = mostBookedHtml;
    }
}

// Initialize all charts
function initializeCharts() {
    // Load revenue chart data
    loadRevenueChartData('6months');
    
    // Load appointment chart data
    loadAppointmentChartData('7days');
    
    // Load staff performance chart data
    loadStaffPerformanceData();
    
    // Load demographics chart data
    loadDemographicsData('gender');
}

// Load revenue chart data
function loadRevenueChartData(timeframe) {
    fetch(`${contextPath}/ReportServlet?action=revenue_chart&timeframe=${timeframe}`)
        .then(response => response.json())
        .then(data => {
            console.log('Revenue chart data loaded:', data);
            
            const ctx = document.getElementById('revenueChart').getContext('2d');
            
            // Create gradient
            const gradient = ctx.createLinearGradient(0, 0, 0, 400);
            gradient.addColorStop(0, 'rgba(102, 126, 234, 0.8)');
            gradient.addColorStop(1, 'rgba(102, 126, 234, 0.1)');
            
            // Destroy existing chart if it exists
            if (revenueChart) {
                revenueChart.destroy();
            }
            
            // Create new chart
            revenueChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: 'Revenue (RM)',
                        data: data.data,
                        backgroundColor: gradient,
                        borderColor: 'rgba(102, 126, 234, 1)',
                        borderWidth: 2,
                        pointBackgroundColor: '#ffffff',
                        pointBorderColor: 'rgba(102, 126, 234, 1)',
                        pointBorderWidth: 2,
                        pointRadius: 4,
                        pointHoverRadius: 6,
                        tension: 0.3,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            mode: 'index',
                            intersect: false,
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            borderColor: '#667eea',
                            borderWidth: 1,
                            callbacks: {
                                label: function(context) {
                                    return 'Revenue: RM ' + context.parsed.y.toLocaleString();
                                }
                            }
                        }
                    },
                    scales: {
                        x: {
                            grid: {
                                display: false
                            }
                        },
                        y: {
                            beginAtZero: true,
                            grid: {
                                color: 'rgba(0, 0, 0, 0.1)'
                            },
                            ticks: {
                                callback: function(value) {
                                    return 'RM ' + value.toLocaleString();
                                }
                            }
                        }
                    },
                    interaction: {
                        intersect: false,
                        mode: 'index'
                    }
                }
            });
        })
        .catch(error => {
            console.error('Error loading revenue chart data:', error);
            showErrorMessage('Failed to load revenue chart. Please try refreshing the page.');
        });
}

// Load appointment chart data
function loadAppointmentChartData(timeframe) {
    fetch(`${contextPath}/ReportServlet?action=appointment_chart&timeframe=${timeframe}`)
        .then(response => response.json())
        .then(data => {
            console.log('Appointment chart data loaded:', data);
            
            const ctx = document.getElementById('appointmentChart').getContext('2d');
            
            // Create gradient
            const gradient = ctx.createLinearGradient(0, 0, 0, 400);
            gradient.addColorStop(0, 'rgba(118, 75, 162, 0.8)');
            gradient.addColorStop(1, 'rgba(118, 75, 162, 0.2)');
            
            // Destroy existing chart if it exists
            if (appointmentChart) {
                appointmentChart.destroy();
            }
            
            // Create new chart
            appointmentChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: 'Appointments',
                        data: data.data,
                        backgroundColor: gradient,
                        borderColor: 'rgba(118, 75, 162, 1)',
                        borderWidth: 1,
                        borderRadius: 4,
                        borderSkipped: false
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            borderColor: '#764ba2',
                            borderWidth: 1
                        }
                    },
                    scales: {
                        x: {
                            grid: {
                                display: false
                            }
                        },
                        y: {
                            beginAtZero: true,
                            grid: {
                                color: 'rgba(0, 0, 0, 0.1)'
                            }
                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('Error loading appointment chart data:', error);
            showErrorMessage('Failed to load appointment chart. Please try refreshing the page.');
        });
}

// Load staff performance chart data
function loadStaffPerformanceData() {
    fetch(`${contextPath}/ReportServlet?action=staff_performance`)
        .then(response => response.json())
        .then(data => {
            console.log('Staff performance data loaded:', data);
            
            const ctx = document.getElementById('staffPerformanceChart').getContext('2d');
            
            // Destroy existing chart if it exists
            if (staffPerformanceChart) {
                staffPerformanceChart.destroy();
            }
            
            // Create new chart
            staffPerformanceChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: 'Rating',
                        data: data.data,
                        backgroundColor: data.backgroundColor,
                        borderColor: 'rgba(255, 255, 255, 0.5)',
                        borderWidth: 1,
                        borderRadius: 4,
                        borderSkipped: false
                    }]
                },
                options: {
                    indexAxis: 'y',
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            callbacks: {
                                label: function(context) {
                                    return 'Rating: ' + context.parsed.x + '/10';
                                }
                            }
                        }
                    },
                    scales: {
                        x: {
                            beginAtZero: true,
                            max: 10,
                            grid: {
                                color: 'rgba(0, 0, 0, 0.1)'
                            }
                        },
                        y: {
                            grid: {
                                display: false
                            }
                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('Error loading staff performance data:', error);
            showErrorMessage('Failed to load staff performance chart. Please try refreshing the page.');
        });
}

// Load demographics chart data
function loadDemographicsData(type) {
    fetch(`${contextPath}/ReportServlet?action=demographics&type=${type}`)
        .then(response => response.json())
        .then(data => {
            console.log('Demographics data loaded:', data);
            
            const ctx = document.getElementById('demographicsChart').getContext('2d');
            
            // Destroy existing chart if it exists
            if (demographicsChart) {
                demographicsChart.destroy();
            }
            
            // Create new chart
            demographicsChart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: data.labels,
                    datasets: [{
                        data: data.data,
                        backgroundColor: data.backgroundColor,
                        borderColor: 'rgba(255, 255, 255, 0.5)',
                        borderWidth: 2,
                        borderRadius: 4,
                        hoverOffset: 10
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                padding: 20,
                                usePointStyle: true
                            }
                        },
                        tooltip: {
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            callbacks: {
                                label: function(context) {
                                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                    const percentage = ((context.parsed / total) * 100).toFixed(1);
                                    return context.label + ': ' + context.parsed + ' (' + percentage + '%)';
                                }
                            }
                        }
                    },
                    cutout: '60%'
                }
            });
        })
        .catch(error => {
            console.error('Error loading demographics data:', error);
            showErrorMessage('Failed to load demographics chart. Please try refreshing the page.');
        });
}

// Set up event listeners for chart controls
function setupChartControls() {
    // Revenue chart timeframe selector
    const revenueTimeframe = document.getElementById('revenueTimeframe');
    if (revenueTimeframe) {
        revenueTimeframe.addEventListener('change', function() {
            loadRevenueChartData(this.value);
        });
    }
    
    // Appointment chart timeframe selector
    const appointmentTimeframe = document.getElementById('appointmentTimeframe');
    if (appointmentTimeframe) {
        appointmentTimeframe.addEventListener('change', function() {
            loadAppointmentChartData(this.value);
        });
    }
    
    // Demographics type selector
    const demographicsType = document.getElementById('demographicsType');
    if (demographicsType) {
        demographicsType.addEventListener('change', function() {
            loadDemographicsData(this.value);
        });
    }
}

// Helper Functions

// Show loading indicator
function showLoadingIndicator() {
    const loadingElement = document.getElementById('loadingModal');
    if (loadingElement) {
        loadingElement.style.display = 'flex';
    }
}

// Hide loading indicator
function hideLoadingIndicator() {
    const loadingElement = document.getElementById('loadingModal');
    if (loadingElement) {
        loadingElement.style.display = 'none';
    }
}

// Show error message
function showErrorMessage(message) {
    // Create error message element if it doesn't exist
    let errorDiv = document.getElementById('errorMessage');
    if (!errorDiv) {
        errorDiv = document.createElement('div');
        errorDiv.id = 'errorMessage';
        errorDiv.className = 'error-message';
        document.querySelector('.analytics-dashboard .container').prepend(errorDiv);
    }
    
    errorDiv.innerHTML = `
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="fa fa-exclamation-circle"></i> ${message}
            <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
    `;
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        const alert = errorDiv.querySelector('.alert');
        if (alert) {
            $(alert).alert('close');
        }
    }, 5000);
}

// Format currency values
function formatCurrency(amount) {
    return parseFloat(amount).toLocaleString('en-MY', {
        style: 'currency',
        currency: 'MYR',
        minimumFractionDigits: 2
    });
}

// Format percentage values
function formatPercentage(value, total) {
    return ((value / total) * 100).toFixed(1) + '%';
}
