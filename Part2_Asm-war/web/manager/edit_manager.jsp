<%@ page import="model.Manager" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<html>
    <head>
        <title>Edit Manager</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    </head>
    <body>
        <h2>Edit Manager</h2>

        <form method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/ManagerServlet">
            <input type="hidden" name="action" value="update" />
            <input type="hidden" name="id" value="${manager.id}" />

            <label>Name:</label>
            <input type="text" name="name" value="${manager.name}" required /><br>

            <label>Email:</label>
            <input type="email" name="email" value="${manager.email}" required /><br>

            <label>Password:</label>
            <input type="password" name="password" value="${manager.password}" required /><br>

            <label>Phone:</label>
            <input type="text" name="phone" value="${manager.phone}" required /><br>

            <label>Gender:</label>
            <select name="gender" required>
                <option value="F" ${manager.gender == 'F' ? 'selected' : ''}>Female</option>
                <option value="M" ${manager.gender == 'M' ? 'selected' : ''}>Male</option>
            </select><br>

            <label>Date of Birth:</label>
            <input type="date" name="dob" value="${manager.dob}" required /><br>

            <label>Profile Picture: </label>
            <input type="file" name="profilePic" accept="image/*" required>

            <input class="login_btn" type="submit" value="Update Manager" />
        </form>

        <br>
        <a href="${pageContext.request.contextPath}/ManagerServlet">Back to List</a>
    </body>
</html>
