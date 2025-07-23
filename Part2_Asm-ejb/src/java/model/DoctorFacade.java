/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

/**
 *
 * @author chris
 */
@Stateless
public class DoctorFacade extends AbstractFacade<Doctor> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public DoctorFacade() {
        super(Doctor.class);
    }

    public Doctor searchEmail(String email) {
        Query q = em.createNamedQuery("Doctor.searchEmail");
        q.setParameter("x", email);
        List<Doctor> result = q.getResultList();
        if (result.size() > 0) {
            return result.get(0);
        }
        return null;
    }
}
