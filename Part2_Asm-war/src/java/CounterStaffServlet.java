
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import model.CounterStaff;
import model.CounterStaffFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/CounterStaffServlet"})
@MultipartConfig

public class CounterStaffServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;

//       protected void processRequest(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//        response.setContentType("text/html;charset=UTF-8");
//        try (PrintWriter out = response.getWriter()) {
//            /* TODO output your page here. You may use following sample code. */
//            out.println("<!DOCTYPE html>");
//            out.println("<html>");
//            out.println("<head>");
//            out.println("<title>Servlet CounterStaffServlet</title>");            
//            out.println("</head>");
//            out.println("<body>");
//            out.println("<h1>Servlet CounterStaffServlet at " + request.getContextPath() + "</h1>");
//            out.println("</body>");
//            out.println("</html>");
//        }
//    }
    //    register new counter staff (not yet validate)
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html");
        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counter_staff = counterStaffFacade.find(id);
            if (counter_staff != null) {
                counterStaffFacade.remove(counter_staff);
            }
            response.sendRedirect("CounterStaffServlet"); // reload list
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counter_staff = counterStaffFacade.find(id);

            if (counter_staff != null) {
                counter_staff.setName(request.getParameter("name"));
                counter_staff.setEmail(request.getParameter("email"));
                counter_staff.setPassword(request.getParameter("password"));
                counter_staff.setPhone(request.getParameter("phone"));
                counter_staff.setGender(request.getParameter("gender"));

                try {
                    String dobStr = request.getParameter("dob");
                    java.util.Date utilDate = new SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                    java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
                    counter_staff.setDob(sqlDate);
                } catch (ParseException e) {
                    e.printStackTrace(); // log or handle
                }

                Part file = request.getPart("profilePic");
                try {
                    String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                    if (uploadedFileName != null) {
                        counter_staff.setProfilePic(uploadedFileName);
                    }
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Upload failed: " + e.getMessage());
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                    return;
                }

                counterStaffFacade.edit(counter_staff);
            }
            response.sendRedirect("CounterStaffServlet");
        } else {

            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String phone = request.getParameter("phone");
            String gender = request.getParameter("gender");
            String dobStr = request.getParameter("dob");

            // Parse date of birth
            Date dob = null;
            if (dobStr != null && !dobStr.isEmpty()) {
                dob = Date.valueOf(dobStr); // yyyy-MM-dd
            }

            String uploadedFileName = null;
            Part file = request.getPart("profilePic");

            try {
                uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
            } catch (IllegalArgumentException e) {
                request.setAttribute("error", e.getMessage());
                request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                return;
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Upload failed: " + e.getMessage());
                request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                return;
            }

            CounterStaff cs = new CounterStaff();
            cs.setName(name);
            cs.setEmail(email);
            cs.setPassword(password);
            cs.setPhone(phone);
            cs.setGender(gender);
            cs.setDob(dob);
            cs.setProfilePic(uploadedFileName);
            try {
                counterStaffFacade.create(cs);
                request.setAttribute("success", "Counter Staff registered successfully.");

            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to register counter staff: " + e.getMessage());
            }
            request.getRequestDispatcher("manager/register_cs.jsp").include(request, response);
        }
    }

//    retreive counter staff detail
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        if ("edit".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counterStaff = counterStaffFacade.find(id);
            request.setAttribute("counterStaff", counterStaff);
            request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
        } else {
            // Default: show list
            List<CounterStaff> counterStaff = counterStaffFacade.findAll();
            request.setAttribute("counterStaffList", counterStaff);
            request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
        }
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
