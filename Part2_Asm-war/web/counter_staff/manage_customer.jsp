<%@page import="model.Customer"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Manager" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Retrieve customer data from request attributes
    List<Customer> customerList = (List<Customer>) request.getAttribute("customerList");

    // Debug output
    System.out.println("customerList: " + (customerList != null ? customerList.size() : "null"));

    // Get search/filter parameters
    String searchQuery = request.getParameter("search");
    String genderFilter = request.getParameter("gender");

    if (searchQuery == null) {
        searchQuery = "";
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
                                    <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
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
                    <% if ("customer_deleted".equals(successMsg)) { %>
                    Customer deleted successfully!
                    <% } else if ("customer_updated".equals(successMsg)) { %>
                    Customer updated successfully!
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
                    Cannot delete customer, please try again.
                    <% } else if ("invalid_data".equals(errorMsg)) { %>
                    Please check all required fields and try again.
                    <% } else { %>
                    An error occurred. Please try again.
                    <% } %>
                </div>
                <% }%>

                <!-- SEARCH AND FILTER SECTION -->
                <div class="search-filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Customer</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/CustomerServlet" class="search-form">
                        <input type="hidden" name="action" value="search">

                        <div class="form-row">
                            <div class="form-group">
                                <label for="search">Search by Name or Email</label>
                                <input type="text" class="form-control" id="search" name="search" 
                                       value="<%= searchQuery%>" placeholder="Enter name or email...">
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
                                <a href="<%= request.getContextPath()%>/CustomerServlet?action=viewAll" class="btn btn-secondary">
                                    <i class="fa fa-refresh"></i> Reset
                                </a>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- CUSTOMER MANAGEMENT SECTION -->
                <div class="staff-management-section wow fadeInUp" data-wow-delay="0.4s">
                      <div class="d-flex justify-content-between align-items-center mb-4">
                      <h3><i class="fa fa-list"></i> Customer Directory</h3>
                        <div>
                            <a href="<%= request.getContextPath()%>/counter_staff/register_customer.jsp" class="add-customer-btn">
                                <i class="fa fa-user"></i> Add Customer
                            </a>
                        </div>
                    </div>

                    <!-- CUSTOMER TABLE -->
                    <div class="staff-table">
                                <% if (customerList != null && !customerList.isEmpty()) { %>
                                <table class="table table-hover" id="customersTable">
                                    <thead>
                                        <tr>
                                            <th class="sortable" onclick="sortTable('customersTable', 0, 'number')">
                                                ID <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('customersTable', 1, 'string')">
                                                Name <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('customersTable', 2, 'string')">
                                                Email <i class="fa fa-sort"></i>
                                            </th>
                                            <th>Phone</th>
                                            <th class="sortable" onclick="sortTable('customersTable', 4, 'date')">
                                                DOB <i class="fa fa-sort"></i>
                                            </th>
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
                                                <%= customer.getDob() != null ? dateFormat.format(customer.getDob()) : "N/A"%>
                                            </td>
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
                                    <i class="fa fa-user"></i>
                                    <h4>No Customer Found</h4>
                                    <p>No customer match your search criteria.</p>
                                    <a href="<%= request.getContextPath()%>/customer/register_customer.jsp" class="btn btn-primary">
                                        <i class="fa fa-plus"></i> Add Customer
                                    </a>
                                </div>
                                <% }%>
                            </div>
                        </div>
                    </div>
                </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // CRUD Functions for Managers
            function viewCustomer(id) {
                window.open('<%= request.getContextPath()%>/CustomerServlet?action=view&id=' + id, '_blank');
            }

            function editCustomer(id) {
                window.location.href = '<%= request.getContextPath()%>/CustomerServlet?action=edit&id=' + id;
            }

            function deleteCustomer(id, name) {
                if (confirm('Are you sure you want to delete customer ' + name + '?\n\nThis action cannot be undone.')) {
                    window.location.href = '<%= request.getContextPath()%>/CustomerServlet?action=delete&id=' + id;
                }
            }

            // Table Sorting Function
            let sortDirections = {}; // Track sort direction for each table and column

            function sortTable(tableId, columnIndex, dataType) {
                const table = document.getElementById(tableId);
                const tbody = table.querySelector('tbody');
                const rows = Array.from(tbody.querySelectorAll('tr'));

                // Determine sort direction
                const sortKey = tableId + '_' + columnIndex;
                const currentDirection = sortDirections[sortKey] || 'asc';
                const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
                sortDirections[sortKey] = newDirection;

                // Update sort icons
                updateSortIcons(tableId, columnIndex, newDirection);

                // Sort rows
                rows.sort((a, b) => {
                    let valueA = a.cells[columnIndex].textContent.trim();
                    let valueB = b.cells[columnIndex].textContent.trim();

                    // Handle different data types
                    if (dataType === 'number') {
                        // Extract numeric values (for ratings like "4.5 ★")
                        valueA = parseFloat(valueA.replace(/[^\d.-]/g, '')) || 0;
                        valueB = parseFloat(valueB.replace(/[^\d.-]/g, '')) || 0;

                        if (newDirection === 'asc') {
                            return valueA - valueB;
                        } else {
                            return valueB - valueA;
                        }
                    } else if (dataType === 'date') {
                        // Handle date parsing
                        valueA = new Date(valueA);
                        valueB = new Date(valueB);

                        if (newDirection === 'asc') {
                            return valueA - valueB;
                        } else {
                            return valueB - valueA;
                        }
                    } else {
                        // String comparison (case-insensitive)
                        valueA = valueA.toLowerCase();
                        valueB = valueB.toLowerCase();

                        if (newDirection === 'asc') {
                            return valueA.localeCompare(valueB);
                        } else {
                            return valueB.localeCompare(valueA);
                        }
                    }
                });

                // Re-append sorted rows
                rows.forEach(row => tbody.appendChild(row));

                // Add visual feedback
                animateTableSort(tableId);
            }

            function updateSortIcons(tableId, activeColumn, direction) {
                const table = document.getElementById(tableId);
                const headers = table.querySelectorAll('th.sortable');

                headers.forEach((header, index) => {
                    const icon = header.querySelector('i');
                    if (index === activeColumn) {
                        // Active column
                        icon.className = direction === 'asc' ? 'fa fa-sort-up' : 'fa fa-sort-down';
                        header.style.color = '#667eea';
                    } else {
                        // Inactive columns
                        icon.className = 'fa fa-sort';
                        header.style.color = '';
                    }
                });
            }

            function animateTableSort(tableId) {
                const table = document.getElementById(tableId);
                table.style.opacity = '0.7';
                setTimeout(() => {
                    table.style.opacity = '1';
                }, 200);
            }

            // Auto-dismiss alerts
            $(document).ready(function () {
                setTimeout(function () {
                    $('.alert').fadeOut();
                }, 5000);

                // Initialize tooltips
                $('[data-toggle="tooltip"]').tooltip();
            });

            // Search form validation - Allow empty searches to show all customers
            document.querySelector('.search-form').addEventListener('submit', function (e) {
                // Allow all searches - no validation needed for customer search
                console.log('Customer search submitted');
            });
        </script>
    </body>
</html>