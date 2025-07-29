<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Manager" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");

    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Retrieve staff data from request attributes
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<CounterStaff> staffList = (List<CounterStaff>) request.getAttribute("staffList");
    List<Manager> managerList = (List<Manager>) request.getAttribute("managerList");

    // Debug output
    System.out.println("manage_staff.jsp: Received data...");
    System.out.println("doctorList: " + (doctorList != null ? doctorList.size() : "null"));
    System.out.println("staffList: " + (staffList != null ? staffList.size() : "null"));
    System.out.println("managerList: " + (managerList != null ? managerList.size() : "null"));

    // Get search/filter parameters
    String searchQuery = request.getParameter("search");
    String roleFilter = request.getParameter("role");
    String genderFilter = request.getParameter("gender");

    if (searchQuery == null) {
        searchQuery = "";
    }
    if (roleFilter == null) {
        roleFilter = "all";
    }
    if (genderFilter == null) {
        genderFilter = "all";
    }

    // Get success/error messages
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Staff - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
    </head>

    <body id="top">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PAGE HEADER -->
        <section class="page-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <h1 class="wow fadeInUp">
                            <i class="fa fa-users" style="color:white"></i>
                            <span style="color:white">Manage Staff</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Add, edit, search, and manage all doctors, counter staff, and managers
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerDashboardServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Manage Staff</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Success/Error Messages -->
                <% if (successMsg != null) { %>
                <div class="alert alert-success alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i>
                    <% if ("staff_added".equals(successMsg)) { %>
                    Staff member added successfully!
                    <% } else if ("staff_updated".equals(successMsg)) { %>
                    Staff member updated successfully!
                    <% } else if ("staff_deleted".equals(successMsg)) { %>
                    Staff member deleted successfully!
                    <% } else { %>
                    Operation completed successfully!
                    <% } %>
                </div>
                <% } %>

                <% if (errorMsg != null) { %>
                <div class="alert alert-danger alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i>
                    <% if ("email_exists".equals(errorMsg)) { %>
                    Email address already exists!
                    <% } else if ("delete_failed".equals(errorMsg)) { %>
                    Cannot delete staff member. They may have active appointments.
                    <% } else if ("invalid_data".equals(errorMsg)) { %>
                    Please check all required fields and try again.
                    <% } else { %>
                    An error occurred. Please try again.
                    <% } %>
                </div>
                <% }%>

                <!-- SEARCH AND FILTER SECTION -->
                <div class="search-filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Staff</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/ManagerServlet" class="search-form">
                        <input type="hidden" name="action" value="search">

                        <div class="form-row">
                            <div class="form-group">
                                <label for="search">Search by Name or Email</label>
                                <input type="text" class="form-control" id="search" name="search" 
                                       value="<%= searchQuery%>" placeholder="Enter name or email...">
                            </div>

                            <div class="form-group">
                                <label for="role">Filter by Role</label>
                                <select class="form-control" id="role" name="role">
                                    <option value="all" <%= "all".equals(roleFilter) ? "selected" : ""%>>All Roles</option>
                                    <option value="doctor" <%= "doctor".equals(roleFilter) ? "selected" : ""%>>Doctors</option>
                                    <option value="counter_staff" <%= "counter_staff".equals(roleFilter) ? "selected" : ""%>>Counter Staff</option>
                                    <option value="manager" <%= "manager".equals(roleFilter) ? "selected" : ""%>>Managers</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="gender">Filter by Gender</label>
                                <select class="form-control" id="gender" name="gender">
                                    <option value="all" <%= "all".equals(genderFilter) ? "selected" : ""%>>All Genders</option>
                                    <option value="M" <%= "M".equals(genderFilter) ? "selected" : ""%>>Male</option>
                                    <option value="F" <%= "F".equals(genderFilter) ? "selected" : ""%>>Female</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fa fa-search"></i> Search
                                </button>
                                <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAll" class="btn btn-secondary">
                                    <i class="fa fa-refresh"></i> Reset
                                </a>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- STAFF MANAGEMENT SECTION -->
                <div class="staff-management-section wow fadeInUp" data-wow-delay="0.4s">
                    <!-- Add New Staff Button -->
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h3><i class="fa fa-list"></i> Staff Directory</h3>
                        <div>
                            <a href="<%= request.getContextPath()%>/manager/register_doctor.jsp" class="add-staff-btn">
                                <i class="fa fa-user-md"></i> Add Doctor
                            </a>
                            <a href="<%= request.getContextPath()%>/manager/register_cs.jsp" class="add-staff-btn">
                                <i class="fa fa-id-badge"></i> Add Counter Staff
                            </a>
                            <a href="<%= request.getContextPath()%>/manager/register_manager.jsp" class="add-staff-btn">
                                <i class="fa fa-cog"></i> Add Manager
                            </a>
                        </div>
                    </div>

                    <!-- Tab Navigation -->
                    <div class="tab-buttons">
                        <button class="tab-btn active" onclick="showTab('doctors')">
                            <i class="fa fa-user-md"></i> Doctors 
                            (<%= doctorList != null ? doctorList.size() : 0%>)
                        </button>
                        <button class="tab-btn" onclick="showTab('staff')">
                            <i class="fa fa-id-badge"></i> Counter Staff 
                            (<%= staffList != null ? staffList.size() : 0%>)
                        </button>
                        <button class="tab-btn" onclick="showTab('managers')">
                            <i class="fa fa-cog"></i> Managers 
                            (<%= managerList != null ? managerList.size() : 0%>)
                        </button>
                    </div>

                    <!-- DOCTORS TAB -->
                    <div id="doctors-tab" class="tab-content">
                        <div class="staff-table">
                            <% if (doctorList != null && !doctorList.isEmpty()) { %>
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Specialization</th>
                                        <th>Phone</th>
                                        <th>Rating</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Doctor doctor : doctorList) {%>
                                    <tr>
                                        <td><%= doctor.getId()%></td>
                                        <td>
                                            <strong><%= doctor.getName()%></strong><br>
                                            <small class="text-muted">
                                                <%= doctor.getGender() != null ? (doctor.getGender().equals("M") ? "Male" : "Female") : "N/A"%>
                                            </small>
                                        </td>
                                        <td><%= doctor.getEmail()%></td>
                                        <td>
                                            <span class="badge badge-info">
                                                <%= doctor.getSpecialization() != null ? doctor.getSpecialization() : "General"%>
                                            </span>
                                        </td>
                                        <td><%= doctor.getPhone() != null ? doctor.getPhone() : "N/A"%></td>
                                        <td>
                                            <% if (doctor.getRating() != null && doctor.getRating() > 0) {%>
                                            <div class="rating-display">
                                                <i class="fa fa-star rating-stars"></i>
                                                <%= String.format("%.1f", doctor.getRating())%>
                                            </div>
                                            <% } else { %>
                                            <span class="text-muted">No rating</span>
                                            <% }%>
                                        </td>
                                        <td>
                                            <span class="status-badge status-active">Active</span>
                                        </td>
                                        <td>
                                            <div class="action-buttons">
                                                <button class="btn btn-sm btn-view" onclick="viewDoctor(<%= doctor.getId()%>)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                                <button class="btn btn-sm btn-edit" onclick="editDoctor(<%= doctor.getId()%>)">
                                                    <i class="fa fa-edit"></i>
                                                </button>
                                                <button class="btn btn-sm btn-delete" onclick="deleteDoctor(<%= doctor.getId()%>, '<%= doctor.getName()%>')">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else {%>
                            <div class="no-data">
                                <i class="fa fa-user-md"></i>
                                <h4>No Doctors Found</h4>
                                <p>No doctors match your search criteria.</p>
                                <a href="<%= request.getContextPath()%>/manager/register_doctor.jsp" class="btn btn-primary">
                                    <i class="fa fa-plus"></i> Add First Doctor
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <!-- COUNTER STAFF TAB -->
                    <div id="staff-tab" class="tab-content" style="display: none;">
                        <div class="staff-table">
                            <% if (staffList != null && !staffList.isEmpty()) { %>
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Phone</th>
                                        <th>Rating</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (CounterStaff staff : staffList) {%>
                                    <tr>
                                        <td><%= staff.getId()%></td>
                                        <td>
                                            <strong><%= staff.getName()%></strong><br>
                                            <small class="text-muted">
                                                <%= staff.getGender() != null ? (staff.getGender().equals("M") ? "Male" : "Female") : "N/A"%>
                                            </small>
                                        </td>
                                        <td><%= staff.getEmail()%></td>
                                        <td><%= staff.getPhone() != null ? staff.getPhone() : "N/A"%></td>
                                        <td>
                                            <% if (staff.getRating() != null && staff.getRating() > 0) {%>
                                            <div class="rating-display">
                                                <i class="fa fa-star rating-stars"></i>
                                                <%= String.format("%.1f", staff.getRating())%>
                                            </div>
                                            <% } else { %>
                                            <span class="text-muted">No rating</span>
                                            <% }%>
                                        </td>
                                        <td>
                                            <span class="status-badge status-active">Active</span>
                                        </td>
                                        <td>
                                            <div class="action-buttons">
                                                <button class="btn btn-sm btn-view" onclick="viewStaff(<%= staff.getId()%>)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                                <button class="btn btn-sm btn-edit" onclick="editStaff(<%= staff.getId()%>)">
                                                    <i class="fa fa-edit"></i>
                                                </button>
                                                <button class="btn btn-sm btn-delete" onclick="deleteStaff(<%= staff.getId()%>, '<%= staff.getName()%>')">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else {%>
                            <div class="no-data">
                                <i class="fa fa-id-badge"></i>
                                <h4>No Counter Staff Found</h4>
                                <p>No counter staff match your search criteria.</p>
                                <a href="<%= request.getContextPath()%>/manager/register_cs.jsp" class="btn btn-primary">
                                    <i class="fa fa-plus"></i> Add First Counter Staff
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <!-- MANAGERS TAB -->
                    <div id="managers-tab" class="tab-content" style="display: none;">
                        <div class="staff-table">
                            <% if (managerList != null && !managerList.isEmpty()) { %>
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Phone</th>
                                        <th>Join Date</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Manager mgr : managerList) {%>
                                    <tr>
                                        <td><%= mgr.getId()%></td>
                                        <td>
                                            <strong><%= mgr.getName()%></strong><br>
                                            <small class="text-muted">
                                                <%= mgr.getGender() != null ? (mgr.getGender().equals("M") ? "Male" : "Female") : "N/A"%>
                                            </small>
                                        </td>
                                        <td><%= mgr.getEmail()%></td>
                                        <td><%= mgr.getPhone() != null ? mgr.getPhone() : "N/A"%></td>
                                        <td>
                                            <%= mgr.getDob() != null ? dateFormat.format(mgr.getDob()) : "N/A"%>
                                        </td>
                                        <td>
                                            <span class="status-badge status-active">Active</span>
                                        </td>
                                        <td>
                                            <div class="action-buttons">
                                                <button class="btn btn-sm btn-view" onclick="viewManager(<%= mgr.getId()%>)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                                <% if (mgr.getId() != loggedInManager.getId()) {%>
                                                <button class="btn btn-sm btn-edit" onclick="editManager(<%= mgr.getId()%>)">
                                                    <i class="fa fa-edit"></i>
                                                </button>
                                                <button class="btn btn-sm btn-delete" onclick="deleteManager(<%= mgr.getId()%>, '<%= mgr.getName()%>')">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                                <% } else { %>
                                                <span class="badge badge-info">Current User</span>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else {%>
                            <div class="no-data">
                                <i class="fa fa-user"></i>
                                <h4>No Managers Found</h4>
                                <p>No managers match your search criteria.</p>
                                <a href="<%= request.getContextPath()%>/manager/register_manager.jsp" class="btn btn-primary">
                                    <i class="fa fa-plus"></i> Add Manager
                                </a>
                            </div>
                            <% }%>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Tab switching functionality
            function showTab(tabName) {
                // Hide all tabs
                document.querySelectorAll('.tab-content').forEach(tab => {
                    tab.style.display = 'none';
                });

                // Remove active class from all buttons
                document.querySelectorAll('.tab-btn').forEach(btn => {
                    btn.classList.remove('active');
                });

                // Show selected tab
                document.getElementById(tabName + '-tab').style.display = 'block';

                // Add active class to clicked button
                event.target.classList.add('active');
            }

            // CRUD Functions for Doctors
            function viewDoctor(id) {
                window.open('<%= request.getContextPath()%>/DoctorServlet?action=view&id=' + id, '_blank');
            }

            function editDoctor(id) {
                window.location.href = '<%= request.getContextPath()%>/manager/edit_doctor.jsp?id=' + id;
            }

            function deleteDoctor(id, name) {
                if (confirm('Are you sure you want to delete Dr. ' + name + '?\n\nThis action cannot be undone.')) {
                    window.location.href = '<%= request.getContextPath()%>/DoctorServlet?action=delete&id=' + id;
                }
            }

            // CRUD Functions for Counter Staff
            function viewStaff(id) {
                window.open('<%= request.getContextPath()%>/CounterStaffServlet?action=view&id=' + id, '_blank');
            }

            function editStaff(id) {
                window.location.href = '<%= request.getContextPath()%>/manager/edit_cs.jsp?id=' + id;
            }

            function deleteStaff(id, name) {
                if (confirm('Are you sure you want to delete ' + name + ' from counter staff?\n\nThis action cannot be undone.')) {
                    window.location.href = '<%= request.getContextPath()%>/CounterStaffServlet?action=delete&id=' + id;
                }
            }

            // CRUD Functions for Managers
            function viewManager(id) {
                window.open('<%= request.getContextPath()%>/ManagerServlet?action=view&id=' + id, '_blank');
            }

            function editManager(id) {
                window.location.href = '<%= request.getContextPath()%>/manager/edit_manager.jsp?id=' + id;
            }

            function deleteManager(id, name) {
                if (confirm('Are you sure you want to delete Manager ' + name + '?\n\nThis action cannot be undone and may affect system administration.')) {
                    window.location.href = '<%= request.getContextPath()%>/ManagerServlet?action=delete&id=' + id;
                }
            }

            // Auto-dismiss alerts
            $(document).ready(function () {
                setTimeout(function () {
                    $('.alert').fadeOut();
                }, 5000);

                // Initialize tooltips
                $('[data-toggle="tooltip"]').tooltip();
            });

            // Search form validation
            document.querySelector('.search-form').addEventListener('submit', function (e) {
                const searchInput = document.getElementById('search');
                if (searchInput.value.trim() === '' &&
                        document.getElementById('role').value === 'all' &&
                        document.getElementById('gender').value === 'all') {
                    e.preventDefault();
                    alert('Please enter search criteria or use filters.');
                }
            });
        </script>
    </body>
</html>