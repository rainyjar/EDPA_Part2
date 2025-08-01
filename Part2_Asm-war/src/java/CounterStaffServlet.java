
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.stream.Collectors;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Manager;

@WebServlet(urlPatterns = {"/CounterStaffServlet"})
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10) // 10MB

public class CounterStaffServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!isManagerLoggedIn(request, response)) {
            return;
        }
        String action = request.getParameter("action");

        if ("register".equals(action)) {
            handleRegister(request, response);
        } else if ("update".equals(action)) {
            handleUpdate(request, response);
        } else if ("delete".equals(action)) {
            handleDelete(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        Manager loggedInManager = null;
        String action = request.getParameter("action");

        if (session != null) {
            loggedInManager = (Manager) session.getAttribute("manager");
        }

        if (!isManagerLoggedIn(request, response)) {
            return;
        }

        try {
            if ("view".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                CounterStaff counterStaff = counterStaffFacade.find(id);
                if (counterStaff != null) {
                    request.setAttribute("counterStaff", counterStaff);
                    request.getRequestDispatcher("/manager/view_cs.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    request.setAttribute("counterStaff", counterStaff);
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
            } else if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    counterStaffFacade.remove(counterStaff);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=counter_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
            }
        } catch (NumberFormatException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
        }

    }

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        CounterStaff counterStaff = new CounterStaff();
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (!populateCounterStaffFromRequest(request, counterStaff, null)) {
            preserveFormData(request);
            request.setAttribute("counterStaff", counterStaff);
            request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
            return;
        }
        counterStaffFacade.create(counterStaff);
        request.setAttribute("success", "Counter staff registered successfully.");
        request.getRequestDispatcher("manager/register_cs.jsp").forward(request, response);
    }

    private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        CounterStaff counterStaff = counterStaffFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (counterStaff == null) {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=counterStaff_not_found");
            return;
        }

        if (!populateCounterStaffFromRequest(request, counterStaff, counterStaff.getEmail())) {
            request.setAttribute("counterStaff", counterStaff);
            response.sendRedirect(request.getContextPath() + "/CounterStaffServlet?action=edit&id=" + counterStaff.getId() + "&error=input_invalid");
            return;
        }

        counterStaffFacade.edit(counterStaff);
        request.setAttribute("success", "Counter Staff updated successfully.");
        request.setAttribute("counterStaff", counterStaff);
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=counter_updated");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        CounterStaff counterStaff = counterStaffFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (counterStaff != null) {
            counterStaffFacade.remove(counterStaff);
        }
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=counter_deleted");
    }

    private boolean populateCounterStaffFromRequest(HttpServletRequest request, CounterStaff counterStaff, String existingEmail) throws IOException, ServletException {
        String name = readFormField(request.getPart("name"));
        String email = readFormField(request.getPart("email"));
        String password = readFormField(request.getPart("password"));
        String phone = readFormField(request.getPart("phone"));
        String gender = readFormField(request.getPart("gender"));
        String dobStr = readFormField(request.getPart("dob"));
        String nric = readFormField(request.getPart("nric"));
        String address = readFormField(request.getPart("address"));

        if (name.isEmpty() || email.isEmpty() || password.isEmpty() || phone.isEmpty() || gender == null || dobStr.isEmpty() || nric.isEmpty() || address.isEmpty()) {
            request.setAttribute("error", "All fields are required.");
            return false;
        }

        if (!email.equals(existingEmail) && counterStaffFacade.searchEmail(email) != null) {
            request.setAttribute("error", "Email address is already registered.");
            return false;
        }

        try {
            counterStaff.setName(name);
            counterStaff.setEmail(email);
            counterStaff.setPassword(password);
            counterStaff.setPhone(phone);
            counterStaff.setGender(gender);
            counterStaff.setDob(Date.valueOf(dobStr));
            counterStaff.setIc(nric);
            counterStaff.setAddress(address);
            
        } catch (Exception e) {
            request.setAttribute("error", "Invalid input format.");
            return false;
        }

        // Handle profile picture
        Part file = request.getPart("profilePic");
        try {
            if (file != null && file.getSize() > 0) {
                String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                counterStaff.setProfilePic(uploadedFileName);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
            return false;
        }

        return true;
    }

    private void preserveFormData(HttpServletRequest request) throws IOException, ServletException {
        CounterStaff counterStaff = new CounterStaff();
        counterStaff.setName(readFormField(request.getPart("name")));
        counterStaff.setEmail(readFormField(request.getPart("email")));
        counterStaff.setPassword(readFormField(request.getPart("password")));
        counterStaff.setPhone(readFormField(request.getPart("phone")));
        counterStaff.setGender(readFormField(request.getPart("gender")));
        counterStaff.setIc(readFormField(request.getPart("nric")));
        counterStaff.setAddress(readFormField(request.getPart("address")));

        String dobStr = readFormField(request.getPart("dob"));
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                counterStaff.setDob(Date.valueOf(dobStr));
            } catch (Exception ignored) {
            }
        }

        request.setAttribute("counterStaff", counterStaff);
    }

    private String readFormField(Part part) throws IOException {
        if (part == null) {
            return "";
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(part.getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n")).trim();
        }
    }

    private boolean isManagerLoggedIn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("manager") == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return false;
            }
            return true;
        } catch (IllegalStateException e) {
            // Already committed response (e.g., forward was called), can't redirect
            System.out.println("Warning: Response already committed. Skipping redirect.");
            return false;
        }
    }

    @Override
    public String getServletInfo() {
        return "CounterStaffServlet - Handles CRUD operations for counter staffs";
    }
}
