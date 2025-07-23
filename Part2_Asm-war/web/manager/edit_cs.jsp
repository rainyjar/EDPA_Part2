<%@ page import="model.CounterStaff" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<html>
    <head>
        <title>Edit Counter Staff</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    </head>
    <body>
        <h2>Edit Counter Staff</h2>

        <form method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/CounterStaffServlet">
            <input type="hidden" name="action" value="update" />
            <input type="hidden" name="id" value="${counterStaff.id}" />

            <label>Name:</label>
            <input type="text" name="name" value="${counterStaff.name}" required /><br>

            <label>Email:</label>
            <input type="email" name="email" value="${counterStaff.email}" required /><br>

            <label>Password:</label>
            <input type="password" name="password" value="${counterStaff.password}" required /><br>

            <label>Phone:</label>
            <input type="text" name="phone" value="${counterStaff.phone}" required /><br>

            <label>Gender:</label>
            <select name="gender" required>
                <option value="F" ${counterStaff.gender == 'F' ? 'selected' : ''}>Female</option>
                <option value="M" ${counterStaff.gender == 'M' ? 'selected' : ''}>Male</option>
            </select><br>

            <label>Date of Birth:</label>
            <input type="date" name="dob" value="${counterStaff.dob}" required /><br>

            <label>Profile Picture: </label>
            <input type="file" name="profilePic" accept="image/*" required>

            <input class="login_btn" type="submit" value="Update Counter Staff" />
        </form>

        <br>
        <a href="${pageContext.request.contextPath}/CounterStaffServlet">Back to List</a>
    </body>
</html>
