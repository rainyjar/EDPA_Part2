<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ page import="model.Manager" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Register Manager</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css" />
    </head>
    <body>
        <div class="box">
            <h2>Register Manager</h2>

            <!-- Error Message -->
            <% if (request.getAttribute("error") != null) {%>
            <div class="msg"><%= request.getAttribute("error")%></div>
            <% }%>

            <form method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/ManagerServlet">
                <label>Name:</label>
                <input type="text" name="name" value="${manager != null ? manager.name : ''}" required /><br>

                <label>Email:</label>
                <input type="email" name="email" value="${manager != null ? manager.email : ''}" required /><br>

                <label>Password:</label>
                <input type="password" name="password" value="${manager != null ? manager.password : ''}" required /><br>

                <label>Phone:</label>
                <input type="text" name="phone" value="${manager != null ? manager.phone : ''}" required /><br>

                <label>Gender:</label>
                <select name="gender" required>
                    <option value="" disabled ${manager == null ? "selected" : ""}>Choose Gender</option>
                    <option value="F" ${manager != null && manager.gender == 'F' ? "selected" : ""}>Female</option>
                    <option value="M" ${manager != null && manager.gender == 'M' ? "selected" : ""}>Male</option>
                </select><br>

                <label>Date of Birth:</label>
                <input type="date" name="dob" value="${manager != null ? manager.dob : ''}" required /><br>

                <!--// profile pic-->
                <label>Profile Picture: </label>
                <input type="file" name="profilePic" accept="image/*" required>

                <input class="login_btn" type="submit" value="Register" />
            </form>
        </div>
    </body>
</html>
