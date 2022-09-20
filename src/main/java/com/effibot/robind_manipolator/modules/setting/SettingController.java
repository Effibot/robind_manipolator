package com.effibot.robind_manipolator.modules.setting;

import com.dlsc.workbenchfx.Workbench;
import com.dlsc.workbenchfx.view.controls.ToolbarItem;
import com.effibot.robind_manipolator.Utils;
import com.effibot.robind_manipolator.bean.RobotBean;
import com.effibot.robind_manipolator.bean.SettingBean;
import com.effibot.robind_manipolator.modules.intro.IntroModule;
import com.effibot.robind_manipolator.processing.P3DMap;
import com.effibot.robind_manipolator.tcp.TCPFacade;
import com.jfoenix.controls.JFXButton;
import com.jogamp.newt.opengl.GLWindow;
import javafx.beans.property.ListProperty;
import javafx.beans.property.SimpleListProperty;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import org.apache.commons.lang.ArrayUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Semaphore;

public class SettingController {
    private static final Logger LOGGER = LoggerFactory.getLogger(SettingController.class.getName());
    private P3DMap p3d;
    private final SettingBean sb;
    private final SettingModule sm;
    private final BlockingQueue<LinkedHashMap<String, Object>> queue;
    private final Workbench wb;
    private RobotBean rb;
    TCPFacade tcp = TCPFacade.getInstance();
    PropertyChangeSupport changes = new PropertyChangeSupport(this);
    
    private final Semaphore[] sequence = {new Semaphore(1),new Semaphore(0)};
    private final Semaphore[] next = {new Semaphore(0),new Semaphore(0)};

    private static final String WIKICONTENT = """
            Selezionare la forma e l'ID da cui far partire il rover, il metodo di
             interpolazione della generazione del cammino e gli angoli
            di roll,pitch e yaw da utilizzare nella cinematica inversa per avvicinare
            il PUMA alla forma e procedere all'identificazione dell'oggetto.
            Nel caso in cui si voglia cambiare i parametri, modificare le scelte e
            premere il bottono Start 2D; altrimenti, per continuare premere Start 3D.
            """;
    public void notifyPropertyChange(String propertyName, Object oldValue, Object newValue) {
        /*
         * Just a wrapper for the fire property change method.
         */
        changes.firePropertyChange(propertyName, oldValue, newValue);
    }

    public void addPropertyChangeListener(PropertyChangeListener l) {
        changes.addPropertyChangeListener(l);
    }

    private Thread t;

    public SettingController(SettingModule sm, SettingBean sb, RobotBean robotBean, Workbench wb) {
        this.sm = sm;
        this.sb = sb;
        this.rb = robotBean;
        this.wb = wb;
        addPropertyChangeListener(tcp);
        this.queue = tcp.getQueue();
    }

    private Thread getNew2DThread() {
        return new Thread(()->{
            try {
                    makePath();
            } catch (InterruptedException e) {
                LOGGER.info("Interrupting 2D Thread",e);
                Thread.currentThread().interrupt();
            }
        });
    }

    public void setIdByShape(String shape) {
        ListProperty<Double> list = new SimpleListProperty<>();
        ArrayList<double[]> shapesID = (ArrayList<double[]>) sb.getShapeIdList();
        switch (shape) {
            case "Sfera" -> list.setValue(arrayToObsListProp(shapesID.get(0)));
            case "Cono" -> list.setValue(arrayToObsListProp(shapesID.get(1)));
            case "Cubo" -> list.setValue(arrayToObsListProp(shapesID.get(2)));
            default -> LOGGER.warn("Forma non esistente");
        }
        sb.setIdList(list);
    }

    private ObservableList<Double> arrayToObsListProp(double[] array) {
        return FXCollections.observableList(
                Arrays.asList(
                        ArrayUtils.toObject(
                                array
                        )
                )
        );
    }

    public void onStart2DAction(JFXButton start) {
        start.setOnAction(event -> {
            t = getNew2DThread();
            t.start();
            sm.getVb().setDisable(true);
        });
    }

    private void makePath() throws InterruptedException {
        // make new packet
        LinkedHashMap<String, Object> pkt = new LinkedHashMap<>();
        pkt.put("PROC", "PATH");
        pkt.put("START", sb.getSelectedId());
        pkt.put("END", sb.shapeToPos());
        pkt.put("METHOD", sb.getSelectedMethod());
        notifyPropertyChange("SEND", null, pkt);
        notifyPropertyChange("RECEIVE", false, true);
        boolean finish = false;
        while (!finish) {
            // set green id
            pkt = queue.take();
            String key = (String) (pkt.keySet().toArray())[0];
            switch (key) {
//                case "Q" -> sb.setGq((double[][]) pkt.get(key));
//                case "dQ" -> sb.setGdq((double[][]) pkt.get(key));
//                case "ddQ" -> sb.setGddq((double[][]) pkt.get(key));
                case "PATHIDS" -> sb.setPathLabel((double[]) pkt.get(key));
                case "ANIMATION" -> sb.setAnimation((byte[]) Utils.decompress((byte[]) pkt.get(key)));
                case "FINISH" ->{
                        finish = true;
                        sm.getVb().setDisable(false);
                }
                default -> LOGGER.warn("Pacchetto non mappato.");
            }
        }
    }


    public void onBackAction(JFXButton back) {
        back.setOnMouseClicked(evt->{
            IntroModule im = new IntroModule();
            sm.close();
            wb.getModules().remove(sm);
            wb.getModules().add(im);
            wb.openModule(im);
        });
    }

    public void onStart3DAction(JFXButton start3d) {
        start3d.setOnAction(event->{


//            rb.stateProperty().addListener(evt -> {
//                switch ( rb.getState()){
//                    case 1-> {
//                        inverseKinematics();
//                    }
//                    case 0->{}
//                    default-> LOGGER.warn("Statw Processing not mapped");
//                }
//            });

            Thread simulationThread = makeSimulation();
            simulationThread.start();
            try {
                sequence[1].acquire();
                rb.setShapePos(sb.getShapeList());
                p3d = new P3DMap(rb.getObsList(), rb, next);
                p3d.run(p3d.getClass().getSimpleName());
                next[0].acquire();
                Thread inverseThread = inverseKinematics();
                inverseThread.start();
                next[1].acquire();
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }




        });
    }

    private Thread makeSimulation() {
        return new Thread(()->{
            try {
                sequence[0].acquire();
//                next[0].acquire();
                // make new packet
                LinkedHashMap<String, Object> pkt = new LinkedHashMap<>();
                pkt.put("PROC","SYM");
                pkt.put("M",20);
                pkt.put("ALPHA",300);
                notifyPropertyChange("SEND", null, pkt);
                notifyPropertyChange("RECEIVE", false, true);
                boolean finish = false;
                while (!finish) {
                    // set green id
                    pkt = queue.take();
                    String key = (String) (pkt.keySet().toArray())[0];
                    LOGGER.info("Getting Rover Infos:");
                    switch (key) {
                        case "ROVER" ->{
                            rb.setRoverPos((double[][]) pkt.get("Qs"));
//                            next[1].release();
                            LOGGER.info("rover pos setted");
                            rb.setRoverVel((double[][]) pkt.get("dQs"));
                            rb.setRoverAcc((double[][]) pkt.get("ddQs"));
                            rb.setError((double[][]) pkt.get("E"));
                        }
//                        rb.setAnimation((byte[]) Utils.decompress((byte[]) pkt.get(key)));
//                        case "ANIMATION" -> {}
                        default -> {
                            finish = true;
                        }
                    }
                }

            } catch (InterruptedException e) {
                LOGGER.info("Interrupting 3D Thread",e);
                Thread.currentThread().interrupt();
            }finally {
                LOGGER.info("Finally Simulink, releasing IK");
                sequence[1].release();
            }
        });
    }

    private Thread inverseKinematics() {
        return new Thread(()->{
            try{
                // make new packet
                LinkedHashMap<String, Object> pkt = new LinkedHashMap<>();
                pkt.put("PROC","IK");
                pkt.put("ROLL",sb.getRoll());
                pkt.put("PITCH",sb.getPitch());
                pkt.put("YAW",sb.getYaw());
                pkt.put("SK",4040);
                notifyPropertyChange("SEND", null, pkt);
                notifyPropertyChange("RECEIVE", false, true);
                boolean finish = false;
                while (!finish) {
                    // set green id
                        pkt = queue.take();

                    String key = (String) (pkt.keySet().toArray())[0];
                    switch (key) {
                        case "Q" ->{
                            LOGGER.info("Receiving Q IK");
                            double[] qlist = (double[]) pkt.get(key);
                            String qstring = ArrayUtils.toString(qlist);
                            qstring =qstring.substring(1,qstring.length()-1);
                            String[] qStringArray = qstring.split(",");
                            ObservableList<Float> qJoint = FXCollections.observableArrayList(
                                    Arrays.stream(qStringArray).map(Float::valueOf).toArray(Float[]::new)
                            );
                            rb.setQ(qJoint);
                        }
                        case "E"->{}
                        case "FINISH"->finish = true;
                        default -> LOGGER.warn("IK not mapped case:{}",key);
                    }
                }
            }catch (InterruptedException e){
                LOGGER.error("Inverse Kinemetics acquire error",e);
                Thread.currentThread().interrupt();
            }finally {
                LOGGER.info("Finally IK");
            }
        });
    }

    public void setOnHoverInfo(ToolbarItem toolbarItem) {
        toolbarItem.setOnClick(evt->
            wb.showInformationDialog(
                    "Wiki "+sm.getName(),
                    WIKICONTENT,
                    buttonType ->{}
            )
        );

    }

    public void closeProcessing() {
        if(p3d!=null){

            GLWindow pane = (GLWindow)p3d.getSurface().getNative();
            pane.destroy();
        }
    }

//    private void makeSimulation() throws InterruptedException {
//        // make new packet
//        LinkedHashMap<String, Object> pkt = new LinkedHashMap<>();
//        pkt.put("PROC","SYM");
//        pkt.put("M",5);
//        pkt.put("ALPHA",300);
//        notifyPropertyChange("SEND", null, pkt);
//        notifyPropertyChange("RECEIVE", false, true);
//        boolean finish = false;
//        while (!finish) {
//            // set green id
//            pkt = queue.take();
//            String key = (String) (pkt.keySet().toArray())[0];
//            switch (key) {
//                case "ROVER" ->{
//                    rb.setRoverPos((double[][]) pkt.get("Qs"));
//                    rb.setRoverVel((double[][]) pkt.get("dQs"));
//                    rb.setRoverAcc((double[][]) pkt.get("ddQs"));
//                    rb.setError((double[][]) pkt.get("E"));
//
//                    p3d.run(p3d.getClass().getSimpleName());
//                }
//                case "ANIMATION" -> rb.setAnimation((byte[]) Utils.decompress((byte[]) pkt.get(key)));
//                default -> finish = true;
//            }
//        }
//    }
}