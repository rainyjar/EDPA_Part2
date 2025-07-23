<%@ page import="model.Doctor" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<html>
    <head>
        <title>Edit Doctor</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    </head>
    <body>
        <h2>Edit Doctor</h2>

        <form method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/DoctorServlet">
            <input type="hidden" name="action" value="update" />
            <input type="hidden" name="id" value="${doctor.id}" />

            <label>Name:</label>
            <input type="text" name="name" value="${doctor.name}" required /><br>

            <label>Email:</label>
            <input type="email" name="email" value="${doctor.email}" required /><br>

            <label>Password:</label>
            <input type="password" name="password" value="${doctor.password}" required /><br>

            <label>Phone:</label>
            <input type="text" name="phone" value="${doctor.phone}" required /><br>

            <label>Gender:</label>
            <select name="gender" required>
                <option value="F" ${doctor.gender == 'F' ? 'selected' : ''}>Female</option>
                <option value="M" ${doctor.gender == 'M' ? 'selected' : ''}>Male</option>
            </select><br>

            <label>Date of Birth:</label>
            <input type="date" name="dob" value="${doctor.dob}" required /><br>

            <label>Specialization</label>
            <input type="text" name="specialization" value="${doctor != null ? doctor.specialization : ''}" required /><br>

            <label>Profile Picture: </label>
            <input type="file" name="profilePic" accept="image/*" required>
            
            <input class="login_btn" type="submit" value="Update Doctor" />
        </form>

        <br>
        <a href="${pageContext.request.contextPath}/DoctorServlet">Back to List</a>
    </body>
</html>
