/**
 * Mock Data Handler for Reports Dashboard
 * This file provides sample data for demonstration when the servlet is not fully configured
 */

// Sample data for dashboard demonstration
const MOCK_DASHBOARD_DATA = {
    // KPI Data
    totalRevenue: "125,450.00",
    totalAppointments: 847,
    totalStaff: 25,
    avgRating: 8.4,
    
    // Top performing doctors
    topDoctors: [
        { 
            name: "Dr. Sarah Smith", 
            specialization: "Cardiology", 
            rating: 9.2, 
            appointments: 145 
        },
        { 
            name: "Dr. John Johnson", 
            specialization: "Neurology", 
            rating: 8.8, 
            appointments: 132 
        },
        { 
            name: "Dr. Emily Lee", 
            specialization: "Pediatrics", 
            rating: 8.5, 
            appointments: 128 
        },
        { 
            name: "Dr. Michael Brown", 
            specialization: "Orthopedics", 
            rating: 8.3, 
            appointments: 119 
        },
        { 
            name: "Dr. Lisa Wilson", 
            specialization: "Dermatology", 
            rating: 8.1, 
            appointments: 115 
        }
    ],
    
    // Most booked doctors
    mostBooked: [
        { 
            name: "Dr. Sarah Smith", 
            specialization: "Cardiology", 
            bookings: 145, 
            revenue: "28,900.00" 
        },
        { 
            name: "Dr. John Johnson", 
            specialization: "Neurology", 
            bookings: 132, 
            revenue: "26,400.00" 
        },
        { 
            name: "Dr. Emily Lee", 
            specialization: "Pediatrics", 
            bookings: 128, 
            revenue: "25,600.00" 
        },
        { 
            name: "Dr. Michael Brown", 
            specialization: "Orthopedics", 
            bookings: 119, 
            revenue: "23,800.00" 
        },
        { 
            name: "Dr. Lisa Wilson", 
            specialization: "Dermatology", 
            bookings: 115, 
            revenue: "23,000.00" 
        }
    ]
};

// Chart data sets
const CHART_DATA = {
    // Revenue chart data
    revenue: {
        "6months": {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            data: [12000, 15000, 18000, 16000, 20000, 22000]
        },
        "12months": {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
            data: [8000, 12000, 15000, 18000, 16000, 20000, 22000, 19000, 21000, 23000, 18000, 25000]
        },
        "ytd": {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'],
            data: [8000, 12000, 15000, 18000, 16000, 20000, 22000, 19000]
        }
    },
    
    // Appointment chart data
    appointments: {
        "7days": {
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            data: [25, 30, 28, 35, 32, 20, 15]
        },
        "30days": {
            labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
            data: [180, 195, 210, 185]
        },
        "90days": {
            labels: ['Month 1', 'Month 2', 'Month 3'],
            data: [770, 820, 695]
        }
    },
    
    // Staff performance data
    staffPerformance: {
        labels: ['Dr. Smith', 'Dr. Johnson', 'Dr. Lee', 'Dr. Brown', 'Dr. Wilson'],
        data: [9.2, 8.8, 8.5, 8.3, 8.1],
        backgroundColor: ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#ffeaa7']
    },
    
    // Demographics data
    demographics: {
        gender: {
            labels: ['Male', 'Female'],
            data: [45, 55],
            backgroundColor: ['#667eea', '#764ba2']
        },
        role: {
            labels: ['Doctors', 'Counter Staff', 'Managers'],
            data: [35, 60, 5],
            backgroundColor: ['#667eea', '#764ba2', '#f093fb']
        },
        age: {
            labels: ['20-30', '31-40', '41-50', '51+'],
            data: [25, 40, 25, 10],
            backgroundColor: ['#667eea', '#764ba2', '#f093fb', '#4ecdc4']
        }
    }
};

// Utility functions for data handling
const DataUtils = {
    
    /**
     * Simulate API delay for realistic loading experience
     */
    delay: function(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    },
    
    /**
     * Format currency values
     */
    formatCurrency: function(amount) {
        return parseFloat(amount).toLocaleString('en-MY', {
            style: 'currency',
            currency: 'MYR',
            minimumFractionDigits: 2
        });
    },
    
    /**
     * Format percentage values
     */
    formatPercentage: function(value, total) {
        return ((value / total) * 100).toFixed(1) + '%';
    },
    
    /**
     * Generate random data for testing
     */
    generateRandomData: function(count, min, max) {
        const data = [];
        for (let i = 0; i < count; i++) {
            data.push(Math.floor(Math.random() * (max - min + 1)) + min);
        }
        return data;
    },
    
    /**
     * Update chart with new data
     */
    updateChart: function(chart, newData) {
        if (chart && newData) {
            chart.data.labels = newData.labels || chart.data.labels;
            chart.data.datasets[0].data = newData.data || chart.data.datasets[0].data;
            chart.update();
        }
    },
    
    /**
     * Create gradient for charts
     */
    createGradient: function(ctx, colorStart, colorEnd) {
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, colorStart);
        gradient.addColorStop(1, colorEnd);
        return gradient;
    }
};

// Enhanced chart configurations
const CHART_CONFIGS = {
    
    revenue: {
        type: 'line',
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
    },
    
    appointments: {
        type: 'bar',
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
    },
    
    staffPerformance: {
        type: 'horizontalBar',
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
    },
    
    demographics: {
        type: 'doughnut',
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
    }
};

// Export for use in reports.jsp
window.MockReportsData = {
    MOCK_DASHBOARD_DATA,
    CHART_DATA,
    DataUtils,
    CHART_CONFIGS
};
