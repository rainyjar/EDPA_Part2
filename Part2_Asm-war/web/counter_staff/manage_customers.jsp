<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Customer" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Counter Staff " + loggedInStaff.getName() + " logged in successfully!");
    }

    // Get customer data
    List<Customer> customers = (List<Customer>) request.getAttribute("customers");
    String searchTerm = (String) request.getAttribute("searchTerm");
    
    // Error and success messages
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Customers - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= contextPath %>/css/staff.css">
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">
        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- CUSTOMER MANAGEMENT SECTION -->
        <section id="customer-management" class="section-padding">
            <div class="container">
                
                <!-- Page Header -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="customer-mgmt-header">
                            <h2><i class="fa fa-users"></i> Customer Management</h2>
                            <p>Welcome, <strong><%= loggedInStaff.getName() %></strong>! Manage customer records efficiently.</p>
                        </div>
                    </div>
                </div>

                <!-- Success/Error Messages -->
                <% if (error != null) { %>
                    <div class="row">
                        <div class="col-md-12">
                            <div class="alert alert-danger alert-dismissible customer-alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-exclamation-circle"></i> <%= error %>
                            </div>
                        </div>
                    </div>
                <% } %>
                
                <% if (success != null) { %>
                    <div class="row">
                        <div class="col-md-12">
                            <div class="alert alert-success alert-dismissible customer-alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-check-circle"></i> <%= success %>
                            </div>
                        </div>
                    </div>
                <% } %>

                <!-- Action Buttons and Search -->
                <div class="row">
                    <div class="col-md-6">
                        <button type="button" class="btn btn-primary customer-mgmt-btn" data-toggle="modal" data-target="#createCustomerModal">
                            <i class="fa fa-plus"></i> Add New Customer
                        </button>
                    </div>
                    <div class="col-md-6">
                        <form class="customer-search-form" method="GET" action="CounterStaffServlet">
                            <input type="hidden" name="action" value="searchCustomers">
                            <div class="input-group">
                                <input type="text" class="form-control customer-search-input" name="search" 
                                       placeholder="Search by name, email, or phone..." value="<%= searchTerm != null ? searchTerm : "" %>">
                                <span class="input-group-btn">
                                    <button class="btn btn-info customer-search-btn" type="submit">
                                        <i class="fa fa-search"></i> Search
                                    </button>
                                </span>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Customer Table -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="customer-table-wrapper">
                            <table class="table table-striped table-hover customer-table">
                                <thead>
                                    <tr>
                                        <th><i class="fa fa-image"></i></th>
                                        <th><i class="fa fa-user"></i> Name</th>
                                        <th><i class="fa fa-envelope"></i> Email</th>
                                        <th><i class="fa fa-phone"></i> Phone</th>
                                        <th><i class="fa fa-venus-mars"></i> Gender</th>
                                        <th><i class="fa fa-birthday-cake"></i> Date of Birth</th>
                                        <th><i class="fa fa-cogs"></i> Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (customers != null && !customers.isEmpty()) { 
                                        SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
                                        for (Customer customer : customers) { %>
                                        <tr>
                                            <td>
                                                <% if (customer.getProfilePic() != null && !customer.getProfilePic().isEmpty()) { %>
                                                    <img src="<%= request.getContextPath() %>/images/profile_pictures/<%= customer.getProfilePic() %>" 
                                                         alt="Profile" class="customer-profile-pic">
                                                <% } else { %>
                                                    <div class="customer-no-pic">
                                                        <i class="fa fa-user"></i>
                                                    </div>
                                                <% } %>
                                            </td>
                                            <td><strong><%= customer.getName() %></strong></td>
                                            <td><%= customer.getEmail() %></td>
                                            <td><%= customer.getPhone() != null ? customer.getPhone() : "N/A" %></td>
                                            <td>
                                                <% if ("Male".equalsIgnoreCase(customer.getGender())) { %>
                                                    <span class="gender-badge male"><i class="fa fa-mars"></i> Male</span>
                                                <% } else if ("Female".equalsIgnoreCase(customer.getGender())) { %>
                                                    <span class="gender-badge female"><i class="fa fa-venus"></i> Female</span>
                                                <% } else { %>
                                                    <span class="gender-badge other">N/A</span>
                                                <% } %>
                                            </td>
                                            <td><%= customer.getDob() != null ? dateFormat.format(customer.getDob()) : "N/A" %></td>
                                            <td>
                                                <div class="customer-actions">
                                                    <button type="button" class="btn btn-sm btn-warning customer-action-btn edit-customer-btn" 
                                                            data-id="<%= customer.getId() %>"
                                                            data-name="<%= customer.getName() %>"
                                                            data-email="<%= customer.getEmail() %>"
                                                            data-phone="<%= customer.getPhone() != null ? customer.getPhone() : "" %>"
                                                            data-gender="<%= customer.getGender() != null ? customer.getGender() : "" %>"
                                                            data-dob="<%= customer.getDob() != null ? new SimpleDateFormat("yyyy-MM-dd").format(customer.getDob()) : "" %>">
                                                        <i class="fa fa-edit"></i>
                                                    </button>
                                                    <button type="button" class="btn btn-sm btn-danger customer-action-btn delete-customer-btn" 
                                                            data-id="<%= customer.getId() %>"
                                                            data-name="<%= customer.getName() %>">
                                                        <i class="fa fa-trash"></i>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    <% } 
                                    } else { %>
                                        <tr>
                                            <td colspan="7" class="text-center customer-no-data">
                                                <i class="fa fa-info-circle"></i> 
                                                <% if (searchTerm != null && !searchTerm.isEmpty()) { %>
                                                    No customers found matching "<%= searchTerm %>"
                                                <% } else { %>
                                                    No customers found
                                                <% } %>
                                            </td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

            </div>
        </section>

        <!-- CREATE CUSTOMER MODAL -->
        <div class="modal fade" id="createCustomerModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content customer-modal">
                    <div class="modal-header customer-modal-header">
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                        <h4 class="modal-title"><i class="fa fa-user-plus"></i> Add New Customer</h4>
                    </div>
                    <form method="POST" action="CounterStaffServlet" enctype="multipart/form-data">
                        <input type="hidden" name="action" value="createCustomer">
                        <div class="modal-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="createName"><i class="fa fa-user"></i> Full Name *</label>
                                        <input type="text" class="form-control customer-form-input" id="createName" 
                                               name="name" required placeholder="Enter full name">
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="createEmail"><i class="fa fa-envelope"></i> Email Address *</label>
                                        <input type="email" class="form-control customer-form-input" id="createEmail" 
                                               name="email" required placeholder="Enter email address">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="createPassword"><i class="fa fa-lock"></i> Password *</label>
                                        <input type="password" class="form-control customer-form-input" id="createPassword" 
                                               name="password" required placeholder="Enter password">
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="createPhone"><i class="fa fa-phone"></i> Phone Number</label>
                                        <input type="tel" class="form-control customer-form-input" id="createPhone" 
                                               name="phone" placeholder="Enter phone number">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="createGender"><i class="fa fa-venus-mars"></i> Gender</label>
                                        <select class="form-control customer-form-input" id="createGender" name="gender">
                                            <option value="">Select Gender</option>
                                            <option value="Male">Male</option>
                                            <option value="Female">Female</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="createDob"><i class="fa fa-birthday-cake"></i> Date of Birth</label>
                                        <input type="date" class="form-control customer-form-input" id="createDob" name="dob">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-12">
                                    <div class="form-group">
                                        <label for="createProfilePic"><i class="fa fa-image"></i> Profile Picture</label>
                                        <input type="file" class="form-control customer-form-input" id="createProfilePic" 
                                               name="profilePic" accept="image/*">
                                        <small class="help-block">Accepted formats: JPG, PNG (Max size: 2MB)</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer customer-modal-footer">
                            <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-primary customer-modal-btn">
                                <i class="fa fa-save"></i> Create Customer
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- EDIT CUSTOMER MODAL -->
        <div class="modal fade" id="editCustomerModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content customer-modal">
                    <div class="modal-header customer-modal-header">
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                        <h4 class="modal-title"><i class="fa fa-edit"></i> Edit Customer</h4>
                    </div>
                    <form method="POST" action="CounterStaffServlet" enctype="multipart/form-data">
                        <input type="hidden" name="action" value="updateCustomer">
                        <input type="hidden" name="id" id="editCustomerId">
                        <div class="modal-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="editName"><i class="fa fa-user"></i> Full Name *</label>
                                        <input type="text" class="form-control customer-form-input" id="editName" 
                                               name="name" required placeholder="Enter full name">
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="editEmail"><i class="fa fa-envelope"></i> Email Address *</label>
                                        <input type="email" class="form-control customer-form-input" id="editEmail" 
                                               name="email" required placeholder="Enter email address">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="editPassword"><i class="fa fa-lock"></i> Password</label>
                                        <input type="password" class="form-control customer-form-input" id="editPassword" 
                                               name="password" placeholder="Leave blank to keep current password">
                                        <small class="help-block">Leave blank to keep current password</small>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="editPhone"><i class="fa fa-phone"></i> Phone Number</label>
                                        <input type="tel" class="form-control customer-form-input" id="editPhone" 
                                               name="phone" placeholder="Enter phone number">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="editGender"><i class="fa fa-venus-mars"></i> Gender</label>
                                        <select class="form-control customer-form-input" id="editGender" name="gender">
                                            <option value="">Select Gender</option>
                                            <option value="Male">Male</option>
                                            <option value="Female">Female</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="editDob"><i class="fa fa-birthday-cake"></i> Date of Birth</label>
                                        <input type="date" class="form-control customer-form-input" id="editDob" name="dob">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-12">
                                    <div class="form-group">
                                        <label for="editProfilePic"><i class="fa fa-image"></i> Profile Picture</label>
                                        <input type="file" class="form-control customer-form-input" id="editProfilePic" 
                                               name="profilePic" accept="image/*">
                                        <small class="help-block">Leave blank to keep current picture. Accepted formats: JPG, PNG (Max size: 2MB)</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer customer-modal-footer">
                            <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-warning customer-modal-btn">
                                <i class="fa fa-save"></i> Update Customer
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- DELETE CONFIRMATION MODAL -->
        <div class="modal fade" id="deleteCustomerModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content customer-modal">
                    <div class="modal-header customer-modal-header-danger">
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                        <h4 class="modal-title"><i class="fa fa-warning"></i> Delete Customer</h4>
                    </div>
                    <div class="modal-body">
                        <p><i class="fa fa-exclamation-triangle"></i> Are you sure you want to delete this customer?</p>
                        <p><strong>Customer:</strong> <span id="deleteCustomerName"></span></p>
                        <p class="text-danger"><small><i class="fa fa-info-circle"></i> This action cannot be undone. All associated data will be permanently removed.</small></p>
                    </div>
                    <div class="modal-footer customer-modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                        <form method="POST" action="CounterStaffServlet" style="display: inline;">
                            <input type="hidden" name="action" value="deleteCustomer">
                            <input type="hidden" name="id" id="deleteCustomerId">
                            <button type="submit" class="btn btn-danger customer-modal-btn">
                                <i class="fa fa-trash"></i> Delete Customer
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>
        
        <!-- JavaScript for customer management -->
        <script>
            $(document).ready(function() {
                // Edit customer button handler
                $('.edit-customer-btn').on('click', function() {
                    var id = $(this).data('id');
                    var name = $(this).data('name');
                    var email = $(this).data('email');
                    var phone = $(this).data('phone');
                    var gender = $(this).data('gender');
                    var dob = $(this).data('dob');
                    
                    $('#editCustomerId').val(id);
                    $('#editName').val(name);
                    $('#editEmail').val(email);
                    $('#editPhone').val(phone);
                    $('#editGender').val(gender);
                    $('#editDob').val(dob);
                    $('#editCustomerModal').modal('show');
                });

                // Delete customer button handler
                $('.delete-customer-btn').on('click', function() {
                    var id = $(this).data('id');
                    var name = $(this).data('name');
                    
                    $('#deleteCustomerId').val(id);
                    $('#deleteCustomerName').text(name);
                    $('#deleteCustomerModal').modal('show');
                });

                // Auto-hide alerts after 5 seconds
                setTimeout(function() {
                    $('.customer-alert').fadeOut('slow');
                }, 5000);
                
                // Form validation
                $('form').on('submit', function(e) {
                    var form = $(this);
                    var action = form.find('input[name="action"]').val();
                    
                    if (action === 'createCustomer' || action === 'updateCustomer') {
                        var name = form.find('input[name="name"]').val();
                        var email = form.find('input[name="email"]').val();
                        
                        if (!name || name.trim() === '') {
                            alert('Please enter customer name');
                            e.preventDefault();
                            return false;
                        }
                        if (!email || email.trim() === '') {
                            alert('Please enter email address');
                            e.preventDefault();
                            return false;
                        }
                        
                        // Email format validation
                        var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                        if (!emailRegex.test(email)) {
                            alert('Please enter a valid email address');
                            e.preventDefault();
                            return false;
                        }
                    }
                });
            });
        </script>
    </body>
</html>
