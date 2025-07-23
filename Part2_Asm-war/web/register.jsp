<%-- 
    Document   : register
    Created on : Jun 17, 2025, 11:17:43 AM
    Author     : guan.kiat
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <title>Register - Medical Center</title>
        <link rel="stylesheet" href="css/log_reg_style.css" />
    </head>
    <body>
        <div class="box">
            <h2 class="register_header">Register</h2>

            <% if (request.getAttribute("error") != null) {%>
            <div class="msg"><%= request.getAttribute("error")%></div>
            <% } else if (request.getAttribute("success") != null) {%>
            <div class="msg" style="background:#e0ffe0; color:#007700; border-color:#007700;">
                <%= request.getAttribute("success")%>
            </div>
            <% }%>

            <form method="post" action="Register">
                <input type="text" name="name" placeholder="Name"  />
                <input type="text" name="email" placeholder="Email"  />
                <input type="password" name="password" placeholder="Password"  />
                <select name="role">
                    <option value="manager">Manager</option>
                    <option value="doctor">Doctor</option>
                    <option value="counter_staff">Counter Staff</option>
                    <option value="customer">Customer</option>
                </select>
                <input class="register_btn" type="submit" value="Register" />
            </form>

            <p style="text-align:center; margin-top:15px;">
                Already have an account? <a href="login.jsp">Login</a>
            </p>
        </div>
    </body>
</html>
