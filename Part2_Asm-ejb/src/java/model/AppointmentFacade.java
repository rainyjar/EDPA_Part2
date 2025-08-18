package model;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

@Stateless
public class AppointmentFacade extends AbstractFacade<Appointment> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public AppointmentFacade() {
        super(Appointment.class);
    }

    public List<Appointment> findByCustomer(Customer customer) {
        return em.createQuery("SELECT a FROM Appointment a WHERE a.customer = :customer", Appointment.class)
                .setParameter("customer", customer)
                .getResultList();
    }

    /**
     * Find appointments for a specific doctor on a specific date
     */
    public List<Appointment> findByDoctorAndDate(int doctorId, String date) {
        Query query = em.createQuery("SELECT a FROM Appointment a WHERE a.doctor.id = :doctorId AND a.appointmentDate = :date AND a.status != 'cancelled'");
        query.setParameter("doctorId", doctorId);
        query.setParameter("date", Date.valueOf(date));
        return query.getResultList();
    }

    // find recent appointments 
    public List<Appointment> findRecentAppointments(int limit) {
        try {
            Query query = em.createQuery("SELECT a FROM Appointment a ORDER BY a.appointmentDate DESC");
            query.setMaxResults(limit);
            return query.getResultList();
        } catch (Exception e) {
            System.err.println("Error finding recent appointments: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Find appointments by status - useful for counter staff operations
     */
    public List<Appointment> findByStatus(String status) {
        try {
            Query query = em.createQuery("SELECT a FROM Appointment a WHERE a.status = :status ORDER BY a.appointmentDate DESC");
            query.setParameter("status", status);
            return query.getResultList();
        } catch (Exception e) {
            System.err.println("Error finding appointments by status: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Find appointments by counter staff - track staff performance
     */
    public List<Appointment> findByCounterStaff(CounterStaff staff) {
        try {
            Query query = em.createQuery("SELECT a FROM Appointment a WHERE a.counterStaff = :staff ORDER BY a.appointmentDate DESC");
            query.setParameter("staff", staff);
            return query.getResultList();
        } catch (Exception e) {
            System.err.println("Error finding appointments by counter staff: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Find appointments by doctor - useful for reassignment
     */
    public List<Appointment> findByDoctor(Doctor doctor) {
        try {
            Query query = em.createQuery("SELECT a FROM Appointment a WHERE a.doctor = :doctor ORDER BY a.appointmentDate DESC");
            query.setParameter("doctor", doctor);
            return query.getResultList();
        } catch (Exception e) {
            System.err.println("Error finding appointments by doctor: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Update appointment status with staff message
     */
    public boolean updateAppointmentStatus(int appointmentId, String newStatus, String staffMessage, CounterStaff staff) {
        try {
            Query query = em.createQuery("UPDATE Appointment a SET a.status = :status, a.staffMessage = :message, a.counterStaff = :staff WHERE a.id = :appointmentId");
            query.setParameter("status", newStatus);
            query.setParameter("message", staffMessage);
            query.setParameter("staff", staff);
            query.setParameter("appointmentId", appointmentId);
            int updatedRows = query.executeUpdate();
            return updatedRows > 0;
        } catch (Exception e) {
            System.err.println("Error updating appointment status: " + e.getMessage());
            return false;
        }
    }

    /**
     * Assign doctor to appointment
     */
    public boolean assignDoctorToAppointment(int appointmentId, Doctor doctor, CounterStaff staff) {
        try {
            Query query = em.createQuery("UPDATE Appointment a SET a.doctor = :doctor, a.status = 'approved', a.counterStaff = :staff WHERE a.id = :appointmentId");
            query.setParameter("doctor", doctor);
            query.setParameter("staff", staff);
            query.setParameter("appointmentId", appointmentId);
            int updatedRows = query.executeUpdate();
            return updatedRows > 0;
        } catch (Exception e) {
            System.err.println("Error assigning doctor to appointment: " + e.getMessage());
            return false;
        }
    }

    /**
     * Check for appointment conflicts during reschedule (excludes specific appointment)
     */
    public boolean hasRescheduleConflict(int appointmentId, int doctorId, Date date, java.sql.Time time) {
        try {
            Query query = em.createQuery("SELECT COUNT(a) FROM Appointment a WHERE a.doctor.id = :doctorId AND a.appointmentDate = :date AND a.appointmentTime = :time AND a.id != :appointmentId AND a.status != 'cancelled'");
            query.setParameter("doctorId", doctorId);
            query.setParameter("date", date);
            query.setParameter("time", time);
            query.setParameter("appointmentId", appointmentId);
            Long count = (Long) query.getSingleResult();
            return count > 0;
        } catch (Exception e) {
            System.err.println("Error checking reschedule conflict: " + e.getMessage());
            return true; // Err on the side of caution
        }
    }

    /**
     * Get appointments that need approval (pending status)
     */
    public List<Appointment> findPendingAppointments() {
        return findByStatus("pending");
    }

    /**
     * Get overdue appointments
     */
    public List<Appointment> findOverdueAppointments() {
        return findByStatus("overdue");
    }
    
    /**
     * Find appointments by doctor and status
     */
    public List<Appointment> findByDoctorAndStatus(int doctorId, String status) {
        try {
            Query query = em.createQuery("SELECT a FROM Appointment a WHERE a.doctor.id = :doctorId AND a.status = :status ORDER BY a.appointmentDate DESC");
            query.setParameter("doctorId", doctorId);
            query.setParameter("status", status);
            return query.getResultList();
        } catch (Exception e) {
            System.err.println("Error finding appointments by doctor and status: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Count appointments for a specific customer
     * @param customer The customer to count appointments for
     * @return The number of appointments for this customer
     */
    public int countByCustomer(Customer customer) {
        try {
            if (customer == null) return 0;
            
            Query query = em.createQuery(
                "SELECT COUNT(a) FROM Appointment a WHERE a.customer.id = :customerId"
            );
            query.setParameter("customerId", customer.getId());
            
            Long result = (Long) query.getSingleResult();
            return result.intValue();
        } catch (Exception e) {
            System.out.println("Error counting appointments for customer: " + e.getMessage());
            return 0;
        }
    }

}
