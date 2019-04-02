import React, { useState, useEffect } from "react";
import styled from "@emotion/styled";
import TodoList from "./TodoList";
import Banner from "./Banner";
import Navbar from "./Navbar";
import PropTypes from 'prop-types';

const AppLayout = styled.div`
  display: grid;
  grid-template-areas:
    "banner banner banner"
    "search list detail";
  grid-template-rows: 140px 1fr;
  grid-template-columns: 5fr 1fr;
  width: 100vw;
  min-height: 100vh;
  background: #5e9668;
`;

App.propTypes = {
  children: PropTypes.node,
};

export default function App(props) {
  return (
    <AppLayout>
      <Banner>
        <Navbar />
      </Banner>
      <TodoList />
    </AppLayout>
  );
}
