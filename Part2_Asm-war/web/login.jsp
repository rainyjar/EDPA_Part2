<%-- 
    Document   : login
    Created on : Jul 19, 2025, 12:57:26 AM
    Author     : chris
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <title>Login - APU Medical Center</title>
        <link rel="stylesheet" href="css/log_reg_style.css" />
    </head>
    <body>
        <div class="box">
            <div class="logo-container">
                <img src="images/amc_logo.png" alt="APU Medical Center" class="logo">
            </div>
            <h2>Login</h2>

            <!-- Error Message -->
            <% if (request.getAttribute("error") != null) {%>
            <div class="msg"><%= request.getAttribute("error")%></div>
            <% }%>

            <form method="post" action="Login">
                <input type="text" name="email" placeholder="Email"  />
                <input type="password" name="password" placeholder="Password"  />
                <select name="role">
                    <option value="manager">Manager</option>
                    <option value="doctor">Doctor</option>
                    <option value="counter_staff">Counter Staff</option>
                    <option value="customer">Customer</option>
                </select>
                <input class="login_btn" type="submit" value="Login" />
            </form>

            <p style="text-align:center; margin-top:15px;">
                Don’t have an account? <a href="register.jsp">Register</a>
            </p>
        </div>
    </body>


</html>
