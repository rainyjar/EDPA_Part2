<%@page import="model.Customer"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Manager" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if manager is logged in
//    Manager loggedInManager = (Manager) session.getAttribute("manager");
//
//    if (loggedInManager == null) {
//        response.sendRedirect(request.getContextPath() + "/login.jsp");
//        return;
//    }
//
    // Retrieve customer data from request attributes
    List<Customer> customerList = (List<Customer>) request.getAttribute("customerList");

    // Debug output
    System.out.println("doctorList: " + (customerList != null ? customerList.size() : "null"));

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

//    // Get success/error messages
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");

//    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Customer - APU Medical Center</title>
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
                            <span style="color:white">Manage Customer</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Add, edit, search, and manage all customers
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <!--return back to CS homepage-->
                                    <a href="<%= request.getContextPath()%>/CounterStaffHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Manage Customer</li>
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
                    Customer added successfully!
                    <% } else if ("staff_updated".equals(successMsg)) { %>
                    Customer updated successfully!
                    <% } else if ("staff_deleted".equals(successMsg)) { %>
                    Customer deleted successfully!
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
                    Cannot delete customer. Please contact manager for more details.
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

                    <!--perform searching function in CounterStaffServlet--> 
                    <form method="GET" action="<%= request.getContextPath()%>/CounterStaffServlet" class="search-form">
                        <input type="hidden" name="action" value="search">

                        <div class="form-row">
                            <div class="form-group">
                                <label for="search">Search by Name or Email</label>
                                <input type="text" class="form-control" id="search" name="search" 
                                       value="<%= searchQuery%>" placeholder="Enter name or email...">
                            </div>

                            <!--add your own filtering logic here-->

                            <!--                            <div class="form-group">
                                                            <label for="role">Filter by Role</label>
                                                            <select class="form-control" id="role" name="role">
                                                                <option value="all" <%= "all".equals(roleFilter) ? "selected" : ""%>>All Roles</option>
                                                                <option value="doctor" <%= "doctor".equals(roleFilter) ? "selected" : ""%>>Doctors</option>
                                                                <option value="counter_staff" <%= "counter_staff".equals(roleFilter) ? "selected" : ""%>>Counter Staff</option>
                                                                <option value="manager" <%= "manager".equals(roleFilter) ? "selected" : ""%>>Managers</option>
                                                            </select>
                                                        </div>-->

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
                        <h3><i class="fa fa-list"></i> Customer Directory</h3>
                        <div>
                            <a href="<%= request.getContextPath()%>/counter_staff/register_customer.jsp" class="add-staff-btn">
                                <i class="fa fa-user-md"></i> Add Customer
                            </a>
                        </div>
                    </div>

                    <!-- Tab Navigation -->
                    <div class="tab-buttons">
                        <button class="tab-btn active" onclick="showTab('customer')">
                            <i class="fa fa-user-md"></i> Customer 
                            (<%= customerList != null ? customerList.size() : 0%>)
                        </button>
                    </div>

                    <!-- DOCTORS TAB -->
                    <div id="doctors-tab" class="tab-content">
                        <div class="staff-table">
                            <% if (customerList != null && !customerList.isEmpty()) { %>
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Phone</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Customer customer : customerList) {%>
                                    <tr>
                                        <td><%= customer.getId()%></td>
                                        <td>
                                            <strong><%= customer.getName()%></strong><br>
                                            <small class="text-muted">
                                                <%= customer.getGender() != null ? (customer.getGender().equals("M") ? "Male" : "Female") : "N/A"%>
                                            </small>
                                        </td>
                                        <td><%= customer.getEmail()%></td>
                                        <td><%= customer.getPhone() != null ? customer.getPhone() : "N/A"%></td>
                                        <td>
                                            <span class="status-badge status-active">Active</span>
                                        </td>
                                        <td>
                                            <div class="action-buttons">
                                                <button class="btn btn-sm btn-view" onclick="viewCustomer(<%= customer.getId()%>)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                                <button class="btn btn-sm btn-edit" onclick="editCustomer(<%= customer.getId()%>)">
                                                    <i class="fa fa-edit"></i>
                                                </button>
                                                <button class="btn btn-sm btn-delete" onclick="deleteCustomer(<%= customer.getId()%>, '<%= customer.getName()%>')">
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
                                <h4>No Customer Found</h4>
                                <p>No customer match your search criteria.</p>
                                <a href="<%= request.getContextPath()%>/counter_staff/register_customer.jsp" class="btn btn-primary">
                                    <i class="fa fa-plus"></i> Add First Customer
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
            function viewCustomer(id) {
                window.open('<%= request.getContextPath()%>/CustomerServlet?action=view&id=' + id, '_blank');
            }

            function editCustomer(id) {
                window.location.href = '<%= request.getContextPath()%>/counter_staff/edit_customer.jsp?id=' + id;
            }

            function deleteCustomer(id, name) {
                if (confirm('Are you sure you want to delete ' + name + '?\n\nThis action cannot be undone.')) {
                    window.location.href = '<%= request.getContextPath()%>/CustomerServlet?action=delete&id=' + id;
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