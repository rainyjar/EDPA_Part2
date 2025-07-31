<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Customer" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Manager" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>

<%
    // Determine user type and get user object
    Object currentUser = null;
    String userType = null;
    String userName = "";
    String userEmail = "";
    String userPhone = "";
    String userGender = "";
    String profilePicName = "";
    int userId = 0;
    Date userDob = null;

    // Doctor-specific fields
    String doctorSpecialization = "";
    Double doctorRating = null;

    // Staff-specific fields  
    Double staffRating = null;

    // Check session for different user types
    Customer customer = (Customer) session.getAttribute("customer");
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    CounterStaff staff = (CounterStaff) session.getAttribute("staff");
    Manager manager = (Manager) session.getAttribute("manager");

    if (customer != null) {
        currentUser = customer;
        userType = "customer";
        userId = customer.getId();
        userName = customer.getName();
        userEmail = customer.getEmail();
        userPhone = customer.getPhone() != null ? customer.getPhone() : "";
        userGender = customer.getGender() != null ? customer.getGender() : "";
        userDob = customer.getDob();
        profilePicName = customer.getProfilePic();
    } else if (doctor != null) {
        currentUser = doctor;
        userType = "doctor";
        userId = doctor.getId();
        userName = doctor.getName();
        userEmail = doctor.getEmail();
        userPhone = doctor.getPhone() != null ? doctor.getPhone() : "";
        userGender = doctor.getGender() != null ? doctor.getGender() : "";
        userDob = doctor.getDob();
        profilePicName = doctor.getProfilePic();
        doctorSpecialization = doctor.getSpecialization() != null ? doctor.getSpecialization() : "";
        doctorRating = doctor.getRating() != null ? doctor.getRating().doubleValue() : null;
    } else if (staff != null) {
        currentUser = staff;
        userType = "staff";
        userId = staff.getId();
        userName = staff.getName();
        userEmail = staff.getEmail();
        userPhone = staff.getPhone() != null ? staff.getPhone() : "";
        userGender = staff.getGender() != null ? staff.getGender() : "";
        userDob = staff.getDob();
        profilePicName = staff.getProfilePic();
        staffRating = staff.getRating() != null ? staff.getRating().doubleValue() : null;
    } else if (manager != null) {
        currentUser = manager;
        userType = "manager";
        userId = manager.getId();
        userName = manager.getName();
        userEmail = manager.getEmail();
        userPhone = manager.getPhone() != null ? manager.getPhone() : "";
        userGender = manager.getGender() != null ? manager.getGender() : "";
        userDob = manager.getDob();
        profilePicName = manager.getProfilePic();
    } else {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Date formatter for displaying date of birth
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
    String dobString = userDob != null ? dateFormat.format(userDob) : "";

   //  working liao
   // String profilePic = profilePicName != null && !profilePicName.isEmpty() ? profilePicName : "default-doc.png";
    String profilePic = (profilePicName != null && !profilePicName.isEmpty())
    ? (request.getContextPath() + "/ImageServlet?folder=profile_pictures&file=" + profilePicName)
    : (request.getContextPath() + "/images/placeholder/user.png");

    // Get success/error messages
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>My Profile - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/profile.css">
    </head>
    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PROFILE SECTION -->
        <section id="profile" class="section" style="min-height: 100vh; background: linear-gradient(135deg, #f8f4ff 0%, #fff5f0 100%);">
            <div class="container">
                <div class="row">
                    <div class="col-md-8 col-md-offset-2">
                        <div class="profile-container wow fadeInUp animated">
                            <!-- Profile Header -->
                            <div class="profile-header">
                                <div class="profile-pic-container"> 
                                    <img src="<%= profilePic %>" class="profile-pic" alt="Profile Picture">
                                    <button type="button" class="pic-upload-btn" onclick="document.getElementById('profilePicInput').click();">
                                        <i class="fa fa-camera"></i>
                                    </button>
                                </div>
                                <div class="profile-name"><%= userName%></div>
                                <div class="profile-email"><%= userEmail%></div>
                            </div>

                            <!-- Profile Body -->
                            <div class="profile-body">
                                <!-- Success/Error Messages -->
                                <% if (successMsg != null) { %>
                                <div class="alert alert-success">
                                    <% if ("profile_updated".equals(successMsg)) { %>
                                    Profile updated successfully!
                                    <% } else if ("password_changed".equals(successMsg)) { %>
                                    Password changed successfully!
                                    <% } else if ("picture_updated".equals(successMsg)) { %>
                                    Profile picture updated successfully!
                                    <% } else { %>
                                    Operation completed successfully!
                                    <% } %>
                                </div>
                                <% } %>

                                <% if (errorMsg != null) { %>
                                <div class="alert alert-danger">
                                    <% if ("invalid_password".equals(errorMsg)) { %>
                                    Current password is incorrect!
                                    <% } else if ("password_mismatch".equals(errorMsg)) { %>
                                    New passwords do not match!
                                    <% } else if ("weak_password".equals(errorMsg)) { %>
                                    Password must be at least 6 characters long!
                                    <% } else if ("upload_failed".equals(errorMsg)) { %>
                                    Failed to upload profile picture. Please try again.
                                    <% } else if ("update_failed".equals(errorMsg)) { %>
                                    Failed to update profile. Please try again.
                                    <% } else if ("invalid_email".equals(errorMsg)) { %>
                                    Please enter a valid email address!
                                    <% } else if ("email_taken".equals(errorMsg)) { %>
                                    This email address is already in use by another account!
                                    <% } else if ("missing_fields".equals(errorMsg)) { %>
                                    Please fill in all required fields!
                                    <% } else if ("invalid_date".equals(errorMsg)) { %>
                                    Please enter a valid date of birth!
                                    <% } else if ("future_date".equals(errorMsg)) { %>
                                    Date of birth cannot be in the future!
                                    <% } else if ("no_file".equals(errorMsg)) { %>
                                    Please select a file to upload!
                                    <% } else if ("invalid_file_type".equals(errorMsg)) { %>
                                    Please upload only image files (JPG, PNG)!
                                    <% } else if ("refresh_failed".equals(errorMsg)) { %>
                                    Failed to refresh profile data. Please logout and login again.
                                    <% } else if ("database_error".equals(errorMsg)) { %>
                                    Database error occurred. Please try again later.
                                    <% } else if ("system_error".equals(errorMsg)) { %>
                                    System error occurred. Please try again later.
                                    <% } else if ("invalid_action".equals(errorMsg)) { %>
                                    Invalid action requested.
                                    <% } else { %>
                                    An error occurred. Please try again.
                                    <% } %>
                                </div>
                                <% }%>

                                <h3 class="section-title-profile">Personal Information</h3>

                                <!-- Profile Update Form -->
                                <form action="<%= request.getContextPath()%>/Profile" method="post" id="profileForm">
                                    <input type="hidden" name="action" value="updateProfile">

                                    <!-- Basic Information Row -->
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label"><%= userType.substring(0, 1).toUpperCase() + userType.substring(1)%> ID</label>
                                                <input type="text" class="form-control" value="<%= userId%>" disabled>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Full Name *</label>
                                                <input type="text" class="form-control" name="name" value="<%= userName%>" required>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Contact Information Row -->
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Email Address *</label>
                                                <input type="email" class="form-control" name="email" value="<%= userEmail%>" required>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Phone Number *</label>
                                                <input type="tel" class="form-control" name="phone" value="<%= userPhone%>" required>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Personal Details Row -->
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Date of Birth *</label>
                                                <input type="date" class="form-control" name="dob" value="<%= dobString%>" 
                                                       max="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date())%>" required>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Gender *</label>
                                                <div style="margin-top: 8px;">
                                                    <label class="gender-radio">
                                                        <input type="radio" name="gender" value="M" <%= "M".equals(userGender) ? "checked" : ""%>>
                                                        Male
                                                    </label>
                                                    <label class="gender-radio">
                                                        <input type="radio" name="gender" value="F" <%= "F".equals(userGender) ? "checked" : ""%>>
                                                        Female
                                                    </label>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Role-Specific Fields (Read-Only) -->
                                    <% if ("doctor".equals(userType)) {%>
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Specialization</label>
                                                <input type="text" class="form-control" value="<%= doctorSpecialization%>" disabled>
                                                <small class="form-text text-muted">Contact administrator to update specialization</small>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-group">
                                                <label class="form-label">Rating</label>
                                                <div class="rating-display">
                                                    <% if (doctorRating != null && doctorRating > 0) { %>
                                                    <div class="star-rating">
                                                        <%
                                                            int fullStars = (int) Math.floor(doctorRating);
                                                            boolean hasHalfStar = (doctorRating - fullStars) >= 0.5;

                                                            for (int i = 1; i <= 5; i++) {
                                                                if (i <= fullStars) { %>
                                                        <i class="fa fa-star star-filled"></i>
                                                        <% } else if (i == fullStars + 1 && hasHalfStar) { %>
                                                        <i class="fa fa-star-half-o star-half"></i>
                                                        <% } else { %>
                                                        <i class="fa fa-star-o star-empty"></i>
                                                        <% }
                                                            }%>
                                                        <span class="rating-text">(<%= String.format("%.1f", doctorRating)%>/5.0)</span>
                                                    </div>
                                                    <% } else { %>
                                                    <div class="no-rating">
                                                        <i class="fa fa-star-o"></i> No ratings yet
                                                    </div>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <% } else if ("staff".equals(userType)) { %>
                                    <div class="row">
                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label class="form-label">Rating</label>
                                                <div class="rating-display">
                                                    <% if (staffRating != null && staffRating > 0) { %>
                                                    <div class="star-rating">
                                                        <%
                                                            int fullStars = (int) Math.floor(staffRating);
                                                            boolean hasHalfStar = (staffRating - fullStars) >= 0.5;

                                                            for (int i = 1; i <= 5; i++) {
                                                                if (i <= fullStars) { %>
                                                        <i class="fa fa-star star-filled"></i>
                                                        <% } else if (i == fullStars + 1 && hasHalfStar) { %>
                                                        <i class="fa fa-star-half-o star-half"></i>
                                                        <% } else { %>
                                                        <i class="fa fa-star-o star-empty"></i>
                                                        <% }
                                                            }%>
                                                        <span class="rating-text">(<%= String.format("%.1f", staffRating)%>/5.0)</span>
                                                    </div>
                                                    <% } else { %>
                                                    <div class="no-rating">
                                                        <i class="fa fa-star-o"></i> No ratings yet
                                                    </div>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <% }%>

                                    <div class="text-center" style="margin-top: 30px;">
                                        <button type="submit" class="btn btn-custom btn-primary-custom">
                                            <i class="fa fa-save"></i> Update Profile
                                        </button>
                                    </div>
                                </form>
                            </div>

                            <!-- Profile Actions -->
                            <div class="profile-actions">
                                <h4 style="margin-bottom: 25px; color: #333;">Account Actions</h4>
                                <button type="button" class="btn btn-custom btn-warning-custom" onclick="openChangePasswordModal()">
                                    <i class="fa fa-key"></i> Change Password
                                </button>
                                <button type="button" class="btn btn-custom btn-danger-custom" onclick="confirmLogout()">
                                    <i class="fa fa-sign-out"></i> Logout
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Hidden Profile Picture Upload Form -->
        <form action="<%= request.getContextPath()%>/Profile" method="post" enctype="multipart/form-data" id="profilePicForm" style="display: none;">
            <input type="hidden" name="action" value="updateProfilePic">
            <input type="file" id="profilePicInput" name="profilePic" accept="image/*" onchange="uploadProfilePicture()">
        </form>

        <!-- Change Password Modal -->
        <div id="changePasswordModal" class="modal">
            <div class="modal-content">
                <span class="close" onclick="closeChangePasswordModal()">&times;</span>
                <h3 style="margin-bottom: 25px; color: #333;">Change Password</h3>

                <form action="<%= request.getContextPath()%>/Profile" method="post" id="changePasswordForm">
                    <input type="hidden" name="action" value="changePassword">

                    <div class="form-group">
                        <label class="form-label">Current Password *</label>
                        <input type="password" class="form-control" name="currentPassword" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">New Password *</label>
                        <input type="password" class="form-control" name="newPassword" id="newPassword" 
                               onkeyup="checkPasswordStrength(); checkPasswordMatch();" 
                               oninput="checkPasswordMatch();" required>
                        <div id="passwordStrength" class="password-strength"></div>
                        <small style="color: #666; margin-top: 5px; display: block;">
                            Password must be at least 6 characters long
                        </small>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Confirm New Password *</label>
                        <input type="password" class="form-control" name="confirmPassword" 
                               onkeyup="checkPasswordMatch();" 
                               oninput="checkPasswordMatch();" required>
                        <small id="passwordMatch" style="margin-top: 5px; display: block;"></small>
                    </div>

                    <div class="text-center" style="margin-top: 25px;">
                        <button type="submit" class="btn btn-custom btn-primary-custom">
                            <i class="fa fa-save"></i> Change Password
                        </button>
                        <button type="button" class="btn btn-custom" style="background: #6c757d; color: white;" onclick="closeChangePasswordModal()">
                            Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>

        <script>
            // Debug function to check session status
            function checkSessionStatus() {
                fetch('<%= request.getContextPath()%>/Profile', {
                    method: 'GET',
                    credentials: 'same-origin'
                })
                        .then(response => {
                            if (response.redirected && response.url.includes('login.jsp')) {
                                console.log('Session expired, redirecting to login');
                                window.location.href = response.url;
                            } else {
                                console.log('Session is still valid');
                            }
                        })
                        .catch(error => {
                            console.error('Error checking session:', error);
                        });
            }

            // Function to refresh profile picture with cache busting
            function refreshProfilePicture() {
                const profilePic = document.getElementById('profilePicDisplay');
                const currentSrc = profilePic.src;

                // Remove any existing timestamp and add a new one
                const baseSrc = currentSrc.split('?')[0];
                profilePic.src = baseSrc + '?t=' + new Date().getTime();

                // Also update the profile picture in the header if it exists
                const headerProfilePic = document.querySelector('.navbar .profile-pic, .header .profile-pic');
                if (headerProfilePic) {
                    const headerBaseSrc = headerProfilePic.src.split('?')[0];
                    headerProfilePic.src = headerBaseSrc + '?t=' + new Date().getTime();
                }
            }

            // Check for success message and refresh picture if needed
            window.addEventListener('DOMContentLoaded', function () {
                const urlParams = new URLSearchParams(window.location.search);
                if (urlParams.get('success') === 'picture_updated') {
                    // Small delay to ensure the file is properly saved
                    setTimeout(function () {
                        refreshProfilePicture();
                        // Check session status after profile picture update
                        setTimeout(checkSessionStatus, 2000);
                    }, 1000);
                }

                // Check session status on page load
                setTimeout(checkSessionStatus, 1000);
            });

            // Profile picture upload
            function uploadProfilePicture() {
                const fileInput = document.getElementById('profilePicInput');
                const file = fileInput.files[0];

                if (file) {
                    // Validate file type
                    if (!file.type.startsWith('image/')) {
                        alert('Please select a valid image file.');
                        fileInput.value = ''; // Clear the input
                        return;
                    }

                    // Validate file size (max 5MB)
                    if (file.size > 5 * 1024 * 1024) {
                        alert('File size must be less than 5MB.');
                        fileInput.value = ''; // Clear the input
                        return;
                    }

                    // Show loading indicator
                    const uploadBtn = document.querySelector('.pic-upload-btn');
                    const originalHTML = uploadBtn.innerHTML;
                    uploadBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i>';
                    uploadBtn.disabled = true;

                    // Preview the image immediately and keep it
                    const reader = new FileReader();
                    reader.onload = function (e) {
                        const profilePic = document.getElementById('profilePicDisplay');
                        profilePic.src = e.target.result;
                        // Store the original src for potential rollback
                        profilePic.setAttribute('data-original-src', profilePic.src);
                    };
                    reader.readAsDataURL(file);

                    // Add a hidden field to track upload start time
                    const form = document.getElementById('profilePicForm');
                    let timeField = form.querySelector('input[name="uploadTime"]');
                    if (!timeField) {
                        timeField = document.createElement('input');
                        timeField.type = 'hidden';
                        timeField.name = 'uploadTime';
                        form.appendChild(timeField);
                    }
                    timeField.value = new Date().getTime();

                    // Submit the form
                    document.getElementById('profilePicForm').submit();
                }
            }

            // Change password modal
            function openChangePasswordModal() {
                document.getElementById('changePasswordModal').style.display = 'block';
            }

            function closeChangePasswordModal() {
                document.getElementById('changePasswordModal').style.display = 'none';
                document.getElementById('changePasswordForm').reset();
                document.getElementById('passwordStrength').className = 'password-strength';
                document.getElementById('passwordMatch').innerHTML = '';

                // Clear any inline styles that might have been added
                document.getElementById('passwordStrength').style.display = '';
                document.getElementById('passwordMatch').style.color = '';
            }

            // Password strength checker
            function checkPasswordStrength() {
                const password = document.getElementById('newPassword').value;
                const strengthBar = document.getElementById('passwordStrength');


                strengthBar.className = 'password-strength';
                if (password.length < 6) {
                    strengthBar.classList.add('strength-weak');
                } else if (password.length < 10) {
                    strengthBar.classList.add('strength-medium');
                } else {
                    strengthBar.classList.add('strength-strong');
                }
            }

            // Password match checker
            function checkPasswordMatch() {
                const newPassword = document.getElementById('newPassword').value;
                const confirmPassword = document.querySelector('input[name="confirmPassword"]').value;
                const matchIndicator = document.getElementById('passwordMatch');

                // If confirm password is empty, don't show any message
                if (confirmPassword === '') {
                    matchIndicator.innerHTML = '';
                    return;
                }

                // If new password is empty but confirm password has content, show error
                if (newPassword === '' && confirmPassword !== '') {
                    matchIndicator.innerHTML = '<span style="color: #dc3545;">✗ Please enter new password first</span>';
                    return;
                }

                // Compare passwords
                if (newPassword === confirmPassword && newPassword !== '') {
                    matchIndicator.innerHTML = '<span style="color: #28a745;">✓ Passwords match</span>';
                } else {
                    matchIndicator.innerHTML = '<span style="color: #dc3545;">✗ Passwords do not match</span>';
                }
            }

            // Just updating the logout confirmation to be universal
            function confirmLogout() {
                if (confirm('Are you sure you want to logout?')) {
                    window.location.href = '<%= request.getContextPath()%>/Logout';
                }
            }

            // Close modal when clicking outside
            window.onclick = function (event) {
                const modal = document.getElementById('changePasswordModal');
                if (event.target === modal) {
                    closeChangePasswordModal();
                }
            }

            // Form validation
            document.getElementById('profileForm').addEventListener('submit', function (e) {
                const phone = document.querySelector('input[name="phone"]').value;
                const phonePattern = /^[0-9+\-\s()]+$/;

                if (!phonePattern.test(phone)) {
                    e.preventDefault();
                    alert('Please enter a valid phone number.');
                    return;
                }

                // Validate date of birth is not in the future
                const dobValue = document.querySelector('input[name="dob"]').value;
                if (dobValue) {
                    const selectedDate = new Date(dobValue);
                    const today = new Date();
                    today.setHours(23, 59, 59, 999); // Set to end of today

                    if (selectedDate > today) {
                        e.preventDefault();
                        alert('Date of birth cannot be in the future.');
                        return;
                    }
                }
            });

            document.getElementById('changePasswordForm').addEventListener('submit', function (e) {
                const newPassword = document.getElementById('newPassword').value;
                const confirmPassword = document.querySelector('input[name="confirmPassword"]').value;

                if (newPassword.length < 6) {
                    e.preventDefault();
                    alert('Password must be at least 6 characters long.');
                    return;
                }

                if (newPassword !== confirmPassword) {
                    e.preventDefault();
                    alert('New passwords do not match.');
                    return;
                }
            });
        </script>
    </body>
</html>