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
public class ManagerFacade extends AbstractFacade<Manager> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public ManagerFacade() {
        super(Manager.class);
    }
    
     public Manager searchEmail(String email) {
        Query q = em.createNamedQuery("Manager.searchEmail");
        q.setParameter("x", email);
        List<Manager> result = q.getResultList();
        if (result.size() > 0) {
            return result.get(0);
        }
        return null;
    }
//    public Manager searchName (String name) {
//        Query q = em.createNamedQuery("Manager.searchName");
//        q.setParameter("x", name);
//        List<Manager> result = q.getResultList();
//        if (result.size() > 0) {
//            return result.get(0);
//        }
//        return null;
//    }
    
    public List<Manager> searchName(String name) {
        return em.createQuery("SELECT m FROM Manager m WHERE LOWER(m.name) LIKE :name", Manager.class)
                 .setParameter("name", "%" + name.toLowerCase() + "%")
                 .getResultList();
    }
}
