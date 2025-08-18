package model;

import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 * Medical Certificate Facade
 */
@Stateless
public class MedicalCertificateFacade extends AbstractFacade<MedicalCertificate> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public MedicalCertificateFacade() {
        super(MedicalCertificate.class);
    }

    /**
     * Find medical certificate by appointment ID
     */
    public MedicalCertificate findByAppointmentId(int appointmentId) {
        try {
            return em.createQuery("SELECT mc FROM MedicalCertificate mc WHERE mc.appointment.id = :appointmentId", MedicalCertificate.class)
                    .setParameter("appointmentId", appointmentId)
                    .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Find medical certificates by doctor
     */
    public java.util.List<MedicalCertificate> findByDoctor(int doctorId) {
        try {
            return em.createQuery("SELECT mc FROM MedicalCertificate mc WHERE mc.doctor.id = :doctorId ORDER BY mc.issueDate DESC", MedicalCertificate.class)
                    .setParameter("doctorId", doctorId)
                    .getResultList();
        } catch (Exception e) {
            return new java.util.ArrayList<>();
        }
    }

        /**
     * Check if a medical certificate exists for the given appointment ID
     * @param appointmentId The appointment ID to check
     * @return true if MC exists, false otherwise
     */
    public boolean existsByAppointmentId(int appointmentId) {
        try {
            Long count = em.createQuery(
                "SELECT COUNT(mc) FROM MedicalCertificate mc WHERE mc.appointment.id = :appointmentId", 
                Long.class)
                .setParameter("appointmentId", appointmentId)
                .getSingleResult();
            
            return count > 0;
        } catch (Exception e) {
            System.out.println("Error checking MC existence: " + e.getMessage());
            return false;
        }
    }
}
