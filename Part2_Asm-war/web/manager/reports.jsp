<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Manager" %>
<%@ page import="model.Appointment" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");

    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    DecimalFormat currencyFormat = new DecimalFormat("#,##0.00");
    SimpleDateFormat dateFormat = new SimpleDateFormat("MMM yyyy");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Analytics & Reports - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/reports.css">
        <!-- Chart.js for data visualization -->
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/date-fns@1.30.1/index.min.js"></script>
        <!-- Mock data for demonstration -->
        <script src="<%= request.getContextPath()%>/js/reports-data.js"></script>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PAGE HEADER -->
        <section class="page-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <h1 class="wow fadeInUp">
                            <i class="fa fa-bar-chart" style="color:white"></i>
                            <span style="color:white">Reports & Analytics</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Demographics, revenue, and staff performance reports                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Reports & Analytics</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- DASHBOARD ANALYTICS -->
        <section class="analytics-dashboard">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="section-title">
                            <h2><i class="fa fa-dashboard"></i> Live Dashboard</h2>
                            <p>Real-time analytics and key performance indicators</p>
                        </div>
                    </div>
                </div>

                <!-- KPI Cards -->
                <div class="row kpi-row">
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card revenue-kpi">
                            <div class="kpi-icon">
                                <i class="fa fa-money"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalRevenue">RM 0.00</h3>
                                <p>Total Revenue</p>
                                <span class="kpi-trend positive">+12.5% this month</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card appointments-kpi">
                            <div class="kpi-icon">
                                <i class="fa fa-calendar-check-o"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalAppointments">0</h3>
                                <p>Total Appointments</p>
                                <span class="kpi-trend positive">+8.3% this month</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card staff-kpi">
                            <div class="kpi-icon">
                                <i class="fa fa-users"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalStaff">0</h3>
                                <p>Total Staff</p>
                                <span class="kpi-trend neutral">Stable</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card rating-kpi">
                            <div class="kpi-icon">
                                <i class="fa fa-star"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="avgRating">0.0</h3>
                                <p>Avg. Staff Rating</p>
                                <span class="kpi-trend positive">+0.3 this month</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row charts-row">
                    <!-- Revenue Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-line-chart"></i> Monthly Revenue Trend</h3>
                                <div class="chart-controls">
                                    <select id="revenueTimeframe" class="form-control">
                                        <option value="6months">Last 6 Months</option>
                                        <option value="12months">Last 12 Months</option>
                                        <option value="ytd">Year to Date</option>
                                    </select>
                                </div>
                            </div>
                            <div class="chart-body">
                                <canvas id="revenueChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Appointments Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-calendar"></i> Daily Appointment Trends</h3>
                                <div class="chart-controls">
                                    <select id="appointmentTimeframe" class="form-control">
                                        <option value="7days">Last 7 Days</option>
                                        <option value="30days">Last 30 Days</option>
                                        <option value="90days">Last 3 Months</option>
                                    </select>
                                </div>
                            </div>
                            <div class="chart-body">
                                <canvas id="appointmentChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Second Charts Row -->
                <div class="row charts-row">
                    <!-- Staff Performance Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-star"></i> Top Performing Staff</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="staffPerformanceChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Demographics Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-pie-chart"></i> Staff Demographics</h3>
                                <div class="chart-controls">
                                    <select id="demographicsType" class="form-control">
                                        <option value="gender">By Gender</option>
                                        <option value="role">By Role</option>
                                        <option value="age">By Age Group</option>
                                    </select>
                                </div>
                            </div>
                            <div class="chart-body">
                                <canvas id="demographicsChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Performance Tables -->
                <div class="row tables-row">
                    <!-- Top Doctors Table -->
                    <div class="col-md-6">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-trophy"></i> Top Performing Doctors</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Doctor</th>
                                            <th>Specialization</th>
                                            <th>Rating</th>
                                            <th>Appointments</th>
                                        </tr>
                                    </thead>
                                    <tbody id="topDoctorsTable">
                                        <!-- Data will be loaded via JavaScript -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- Most Booked Doctors -->
                    <div class="col-md-6">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-calendar-plus-o"></i> Most Booked Doctors</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Doctor</th>
                                            <th>Specialization</th>
                                            <th>Bookings</th>
                                            <th>Revenue</th>
                                        </tr>
                                    </thead>
                                    <tbody id="mostBookedTable">
                                        <!-- Data will be loaded via JavaScript -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- REPORT DOWNLOAD SECTION -->
        <section class="quick-actions">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="section-title text-center">
                            <h2><i class="fa fa-download"></i> View Reports</h2>
                            <p>View and download comprehensive staff, revenue, and appointment reports.</p>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <!-- Staff Performance Report -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/manager/reports/staff-performance.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.2s">
                                <div class="action-icon">
                                    <i class="fa fa-star"></i>
                                </div>
                                <div class="action-title">Staff Performance</div>
                                <div class="action-desc">Top rated doctors, counter staff, and performance insights</div>
                            </div>
                        </a>
                    </div>

                    <!-- Appointment Analytics -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/manager/reports/appointment-analytics.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.3s">
                                <div class="action-icon">
                                    <i class="fa fa-calendar"></i>
                                </div>
                                <div class="action-title">Appointment Analytics</div>
                                <div class="action-desc">Booking trends, popular doctors, and appointment statistics</div>
                            </div>
                        </a>
                    </div>

                    <!-- Staff Demographics -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/manager/reports/staff-demographics.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.4s">
                                <div class="action-icon">
                                    <i class="fa fa-users"></i>
                                </div>
                                <div class="action-title">Staff Demographics</div>
                                <div class="action-desc">Gender distribution, age groups, and workforce analysis</div>
                            </div>
                        </a>
                    </div>

                    <!-- Revenue Analytics -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/manager/reports/revenue-analytics.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.5s">
                                <div class="action-icon">
                                    <i class="fa fa-money"></i>
                                </div>
                                <div class="action-title">Revenue Analytics</div>
                                <div class="action-desc">Monthly trends, doctor revenue, and financial insights</div>
                            </div>
                        </a>
                    </div>
                </div>

                <!-- Second Row -->
                <div class="row" style="margin-top: 20px;">
                    <!-- Customer Analytics Report -->
                    <div class="col-md-3 col-sm-6 col-md-offset-4 col-sm-offset-3">
                        <a href="<%= request.getContextPath()%>/manager/reports/customer-analytics.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.6s">
                                <div class="action-icon">
                                    <i class="fa fa-user-md"></i>
                                </div>
                                <div class="action-title">Customer Analytics</div>
                                <div class="action-desc">Patient demographics, peak hours, popular treatments, and visit patterns</div>
                            </div>
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- Loading Modal -->
        <div id="loadingModal" class="loading-modal">
            <div class="loading-content">
                <div class="spinner"></div>
                <h3>Generating Report...</h3>
                <p>Please wait while we prepare your PDF report.</p>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Global variables for charts
            let revenueChart, appointmentChart, staffPerformanceChart, demographicsChart;

            $(document).ready(function () {
                console.log('Reports dashboard loading...');

                // Load initial data and charts
                loadDashboardData();
                initializeCharts();

                // Set up event listeners for chart controls
                setupChartControls();
            });

            function loadDashboardData() {
                // Try to load real data via AJAX first, fallback to mock data
                $.ajax({
                    url: '<%= request.getContextPath()%>/ReportsServlet',
                    type: 'GET',
                    data: {action: 'dashboard_data'},
                    dataType: 'json',
                    timeout: 5000,
                    success: function (data) {
                        console.log('Real data loaded successfully');
                        updateKPIs(data);
                        updateTables(data);
                    },
                    error: function (xhr, status, error) {
                        console.log('Loading mock data for demonstration');
                        // Load mock data for demonstration
                        loadMockData();
                    }
                });
            }

            function loadMockData() {
                // Use mock data from reports-data.js
                const mockData = window.MockReportsData.MOCK_DASHBOARD_DATA;
                updateKPIs(mockData);
                updateTables(mockData);
            }

            function updateKPIs(data) {
                $('#totalRevenue').text('RM ' + (data.totalRevenue || '0.00'));
                $('#totalAppointments').text(data.totalAppointments || '0');
                $('#totalStaff').text(data.totalStaff || '0');
                $('#avgRating').text((data.avgRating || '0.0') + '/10');
            }

            function updateTables(data) {
                // Update top doctors table
                if (data.topDoctors) {
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
                    $('#topDoctorsTable').html(topDoctorsHtml);
                }

                // Update most booked doctors table
                if (data.mostBooked) {
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
                    $('#mostBookedTable').html(mostBookedHtml);
                }
            }

            function initializeCharts() {
                const {CHART_DATA, CHART_CONFIGS, DataUtils} = window.MockReportsData;

                // Revenue Chart
                const revenueCtx = document.getElementById('revenueChart').getContext('2d');
                const revenueGradient = DataUtils.createGradient(revenueCtx, 'rgba(102, 126, 234, 0.8)', 'rgba(102, 126, 234, 0.1)');

                revenueChart = new Chart(revenueCtx, {
                    type: 'line',
                    data: {
                        labels: CHART_DATA.revenue["6months"].labels,
                        datasets: [{
                                label: 'Revenue (RM)',
                                data: CHART_DATA.revenue["6months"].data,
                                borderColor: '#667eea',
                                backgroundColor: revenueGradient,
                                borderWidth: 3,
                                fill: true,
                                tension: 0.4,
                                pointBackgroundColor: '#667eea',
                                pointBorderColor: '#ffffff',
                                pointBorderWidth: 2,
                                pointRadius: 5,
                                pointHoverRadius: 7
                            }]
                    },
                    options: CHART_CONFIGS.revenue.options
                });

                // Appointment Chart
                const appointmentCtx = document.getElementById('appointmentChart').getContext('2d');
                appointmentChart = new Chart(appointmentCtx, {
                    type: 'bar',
                    data: {
                        labels: CHART_DATA.appointments["7days"].labels,
                        datasets: [{
                                label: 'Appointments',
                                data: CHART_DATA.appointments["7days"].data,
                                backgroundColor: '#764ba2',
                                borderColor: '#667eea',
                                borderWidth: 1,
                                borderRadius: 5,
                                borderSkipped: false
                            }]
                    },
                    options: CHART_CONFIGS.appointments.options
                });

                // Staff Performance Chart
                const staffCtx = document.getElementById('staffPerformanceChart').getContext('2d');
                staffPerformanceChart = new Chart(staffCtx, {
                    type: 'bar',
                    data: {
                        labels: CHART_DATA.staffPerformance.labels,
                        datasets: [{
                                label: 'Rating',
                                data: CHART_DATA.staffPerformance.data,
                                backgroundColor: CHART_DATA.staffPerformance.backgroundColor,
                                borderWidth: 1,
                                borderRadius: 5
                            }]
                    },
                    options: {
                        indexAxis: 'y',
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                display: false
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

                // Demographics Chart
                const demoCtx = document.getElementById('demographicsChart').getContext('2d');
                demographicsChart = new Chart(demoCtx, {
                    type: 'doughnut',
                    data: {
                        labels: CHART_DATA.demographics.gender.labels,
                        datasets: [{
                                data: CHART_DATA.demographics.gender.data,
                                backgroundColor: CHART_DATA.demographics.gender.backgroundColor,
                                borderWidth: 3,
                                borderColor: '#ffffff'
                            }]
                    },
                    options: CHART_CONFIGS.demographics.options
                });
            }

            function setupChartControls() {
                $('#revenueTimeframe').change(function () {
                    updateRevenueChart($(this).val());
                });

                $('#appointmentTimeframe').change(function () {
                    updateAppointmentChart($(this).val());
                });

                $('#demographicsType').change(function () {
                    updateDemographicsChart($(this).val());
                });
            }

            function updateRevenueChart(timeframe) {
                const {CHART_DATA, DataUtils} = window.MockReportsData;
                const newData = CHART_DATA.revenue[timeframe];
                if (newData && revenueChart) {
                    DataUtils.updateChart(revenueChart, newData);
                }
            }

            function updateAppointmentChart(timeframe) {
                const {CHART_DATA, DataUtils} = window.MockReportsData;
                const newData = CHART_DATA.appointments[timeframe];
                if (newData && appointmentChart) {
                    DataUtils.updateChart(appointmentChart, newData);
                }
            }

            function updateDemographicsChart(type) {
                const {CHART_DATA} = window.MockReportsData;
                const newData = CHART_DATA.demographics[type];

                if (newData && demographicsChart) {
                    demographicsChart.data.labels = newData.labels;
                    demographicsChart.data.datasets[0].data = newData.data;
                    demographicsChart.data.datasets[0].backgroundColor = newData.backgroundColor;
                    demographicsChart.update();
                }
            }

            function downloadReport(reportType) {
                // Show loading modal
                $('#loadingModal').show();

                // Create form and submit
                const form = document.createElement('form');
                form.method = 'GET';
                form.action = '<%= request.getContextPath()%>/ReportsServlet';
                form.style.display = 'none';

                const actionInput = document.createElement('input');
                actionInput.name = 'action';
                actionInput.value = 'download';
                form.appendChild(actionInput);

                const typeInput = document.createElement('input');
                typeInput.name = 'type';
                typeInput.value = reportType;
                form.appendChild(typeInput);

                document.body.appendChild(form);
                form.submit();
                document.body.removeChild(form);

                // Hide loading modal after delay
                setTimeout(() => {
                    $('#loadingModal').hide();
                }, 3000);
            }
        </script>
    </body>
</html>
